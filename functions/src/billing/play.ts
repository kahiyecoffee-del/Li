import { createHash } from "node:crypto";

import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { google } from "googleapis";

/**
 * Google Play subscription verification (Play Developer API v3,
 * purchases.subscriptionsv2). The Functions service account must be granted
 * "View financial data" + "Manage orders and subscriptions" in Play Console.
 */
export interface SubscriptionState {
  active: boolean;
  productId?: string;
  expiresAt?: Date;
  autoRenewing: boolean;
  state: string;
}

const ACTIVE_STATES = new Set(["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"]);

export async function fetchSubscription(packageName: string, token: string): Promise<SubscriptionState> {
  const auth = new google.auth.GoogleAuth({ scopes: ["https://www.googleapis.com/auth/androidpublisher"] });
  const api = google.androidpublisher({ version: "v3", auth });
  const { data } = await api.purchases.subscriptionsv2.get({ packageName, token });
  return interpretSubscription(data as unknown as Record<string, unknown>);
}

/** Pure interpretation of a SubscriptionPurchaseV2 payload (unit-tested). */
export function interpretSubscription(data: Record<string, unknown>): SubscriptionState {
  const state = typeof data.subscriptionState === "string" ? data.subscriptionState : "UNKNOWN";
  const items = Array.isArray(data.lineItems) ? (data.lineItems as Record<string, unknown>[]) : [];
  let latest: Record<string, unknown> | undefined;
  for (const li of items) {
    if (!latest || String(li.expiryTime ?? "") > String(latest.expiryTime ?? "")) latest = li;
  }
  const expiry = typeof latest?.expiryTime === "string" ? new Date(latest.expiryTime) : undefined;
  const autoRenew = (latest?.autoRenewingPlan as Record<string, unknown> | undefined)?.autoRenewEnabled === true;
  const notExpired = !expiry || expiry.getTime() > Date.now();
  return {
    active: ACTIVE_STATES.has(state) && notExpired,
    productId: typeof latest?.productId === "string" ? latest.productId : undefined,
    expiresAt: expiry,
    autoRenewing: autoRenew,
    state,
  };
}

export function tokenHash(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

/**
 * Binds a purchase token to one account (prevents sharing a token across
 * accounts) and writes the entitlement. Returns false if the token belongs
 * to another user.
 */
export async function applyEntitlement(db: Firestore, uid: string, token: string, s: SubscriptionState): Promise<boolean> {
  const purchaseRef = db.collection("purchases").doc(tokenHash(token));
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(purchaseRef);
    const owner = existing.data()?.uid as string | undefined;
    if (owner && owner !== uid) return false;
    tx.set(purchaseRef, { uid, productId: s.productId ?? null, state: s.state, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    tx.set(db.collection("entitlements").doc(uid), {
      premium: s.active,
      productId: s.productId ?? null,
      expiresAt: s.expiresAt ? Timestamp.fromDate(s.expiresAt) : null,
      autoRenewing: s.autoRenewing,
      state: s.state,
      source: "google_play",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

/** Handles a Real-time Developer Notification (renewal, cancel, expiry…). */
export async function handleRtdn(db: Firestore, packageName: string, payload: Record<string, unknown>): Promise<void> {
  const n = payload.subscriptionNotification as Record<string, unknown> | undefined;
  const token = typeof n?.purchaseToken === "string" ? n.purchaseToken : undefined;
  if (!token) return;
  const snap = await db.collection("purchases").doc(tokenHash(token)).get();
  const uid = snap.data()?.uid as string | undefined;
  const state = await fetchSubscription(packageName, token);
  await db.collection("billing_events").add({
    type: n?.notificationType ?? null,
    state: state.state,
    uid: uid ?? null,
    at: FieldValue.serverTimestamp(),
  });
  if (uid) await applyEntitlement(db, uid, token, state);
}
