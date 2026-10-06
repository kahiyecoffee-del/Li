import { getAuth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";

/**
 * Permanently deletes everything stored for a user: their synced data,
 * entitlement, usage counters, rate limits, purchase-token bindings and the
 * auth account. AI response cache entries are keyed by input hashes and hold
 * no user identifiers. Google Play subscriptions must be cancelled by the
 * user in Play (we cannot cancel on their behalf).
 */
export async function deleteUserData(db: Firestore, uid: string): Promise<void> {
  await db.recursiveDelete(db.collection("users").doc(uid));
  await db.recursiveDelete(db.collection("usage").doc(uid));
  await db.collection("entitlements").doc(uid).delete();
  await db.collection("rate_limits").doc(uid).delete();
  const purchases = await db.collection("purchases").where("uid", "==", uid).get();
  await Promise.all(purchases.docs.map((d) => d.ref.delete()));
  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
}
