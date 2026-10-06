/**
 * Dayly Cloud Functions (2nd gen).
 *
 * Callable functions require Firebase Auth and (by default) App Check.
 * Secrets: ANTHROPIC_API_KEY | OPENAI_API_KEY | GEMINI_API_KEY, NEWS_API_KEY.
 * Params:  AI_PROVIDER, NEWS_PROVIDER, ENFORCE_APP_CHECK, REWARD_MODE,
 *          ANDROID_PACKAGE, PREMIUM_PRODUCT_IDS (see README → Backend).
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { defineBoolean, defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { deleteUserData } from "./account/account";
import { verifySsv } from "./ads/ssv";
import { AiCache } from "./ai/cache";
import { Deps, handleChat, handleCredits, handleReward, handleTask } from "./ai/handlers";
import { ANTHROPIC_API_KEY, GEMINI_API_KEY, getProvider, OPENAI_API_KEY } from "./ai/registry";
import { applyEntitlement, fetchSubscription, handleRtdn } from "./billing/play";
import { getServerConfig } from "./config/serverConfig";
import { dayKey, requireAuth, str } from "./lib/util";
import { aggregateDay } from "./metrics/aggregate";
import { getHeadlines, GNewsProvider, NewsApiProvider } from "./news/news";
import { UsageStore } from "./usage/credits";

initializeApp();
const db = getFirestore();

const ENFORCE_APP_CHECK = defineBoolean("ENFORCE_APP_CHECK", { default: true });
/** "callable": client reports reward (capped/day). "ssv": only AdMob SSV callbacks grant rewards. */
const REWARD_MODE = defineString("REWARD_MODE", { default: "callable" });
const NEWS_PROVIDER = defineString("NEWS_PROVIDER", { default: "gnews" });
const NEWS_API_KEY = defineSecret("NEWS_API_KEY");
const ANDROID_PACKAGE = defineString("ANDROID_PACKAGE", { default: "com.dayly.app" });
const PREMIUM_PRODUCT_IDS = defineString("PREMIUM_PRODUCT_IDS", { default: "dayly_premium_monthly,dayly_premium_yearly" });

setGlobalOptions({ region: "us-central1", maxInstances: 20 });

const AI_SECRETS = [ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY];
const callable = { enforceAppCheck: ENFORCE_APP_CHECK, timeoutSeconds: 60, memory: "512MiB" as const };

async function deps(): Promise<Deps> {
  return {
    provider: getProvider(),
    usage: new UsageStore(db),
    cache: new AiCache(db),
    config: await getServerConfig(),
    now: () => new Date(),
  };
}

export const aiChat = onCall({ ...callable, secrets: AI_SECRETS }, async (req) =>
  handleChat(requireAuth(req.auth), req.data, await deps()),
);

export const aiTask = onCall({ ...callable, secrets: AI_SECRETS }, async (req) =>
  handleTask(requireAuth(req.auth), req.data, await deps()),
);

export const getAiCredits = onCall(callable, async (req) =>
  handleCredits(requireAuth(req.auth), req.data, { usage: new UsageStore(db), config: await getServerConfig(), now: () => new Date() }),
);

export const grantAdReward = onCall(callable, async (req) => {
  const uid = requireAuth(req.auth);
  const d = { usage: new UsageStore(db), config: await getServerConfig(), now: () => new Date() };
  // In SSV mode rewards arrive via admobSsv; this call just returns credits.
  if (REWARD_MODE.value() === "ssv") return handleCredits(uid, req.data, d);
  return handleReward(uid, req.data, d);
});

/** AdMob SSV callback URL (configure in AdMob → ad unit → server-side verification). */
export const admobSsv = onRequest({ maxInstances: 10 }, async (req, res) => {
  const raw = req.originalUrl.split("?")[1] ?? "";
  const payload = await verifySsv(raw);
  if (!payload) {
    res.status(400).send("invalid");
    return;
  }
  const txRef = db.collection("ssv_transactions").doc(payload.transactionId.slice(0, 200));
  const fresh = await db.runTransaction(async (tx) => {
    if ((await tx.get(txRef)).exists) return false;
    tx.set(txRef, { uid: payload.userId, placement: payload.customData, at: new Date() });
    return true;
  });
  if (fresh && REWARD_MODE.value() === "ssv") {
    const usage = new UsageStore(db);
    const now = new Date();
    await usage.grantReward(payload.userId, dayKey(now), await getServerConfig(), await usage.isPremium(payload.userId, now));
  }
  res.status(200).send("ok");
});

export const getNews = onCall({ ...callable, secrets: [NEWS_API_KEY] }, async (req) => {
  requireAuth(req.auth);
  const key = NEWS_API_KEY.value();
  if (!key) throw new HttpsError("failed-precondition", "News is not configured.");
  const provider = NEWS_PROVIDER.value() === "newsapi" ? new NewsApiProvider(key) : new GNewsProvider(key);
  const topics = Array.isArray(req.data?.topics) ? (req.data.topics as unknown[]).map((t) => str(t, 20)) : ["world"];
  return { articles: await getHeadlines(db, provider, topics, str(req.data?.language, 5) || "en") };
});

export const verifyPurchase = onCall(callable, async (req) => {
  const uid = requireAuth(req.auth);
  const productId = str(req.data?.productId, 100);
  const token = str(req.data?.purchaseToken, 2000);
  const allowed = PREMIUM_PRODUCT_IDS.value().split(",").map((s) => s.trim());
  if (!token || !allowed.includes(productId)) throw new HttpsError("invalid-argument", "Unknown product.");
  let state;
  try {
    state = await fetchSubscription(ANDROID_PACKAGE.value(), token);
  } catch (e) {
    logger.error("Play verification failed", e);
    throw new HttpsError("unavailable", "Could not verify purchase.");
  }
  if (state.productId && !allowed.includes(state.productId)) throw new HttpsError("permission-denied", "Product mismatch.");
  if (!(await applyEntitlement(db, uid, token, state))) throw new HttpsError("permission-denied", "Purchase belongs to another account.");
  return { premium: state.active, expiresAt: state.expiresAt?.toISOString() ?? null };
});

/** Google Play Real-time Developer Notifications (Pub/Sub topic "play-billing"). */
export const playRtdn = onMessagePublished("play-billing", async (event) => {
  const json = event.data.message.json as Record<string, unknown> | undefined;
  if (json) await handleRtdn(db, ANDROID_PACKAGE.value(), json);
});

export const deleteAccount = onCall(callable, async (req) => {
  const uid = requireAuth(req.auth);
  await deleteUserData(db, uid);
  logger.info("account_deleted");
  return { deleted: true };
});

/** Yesterday's (UTC) AI cost and rewarded-ad metrics. */
export const dailyMetrics = onSchedule({ schedule: "15 3 * * *", timeZone: "UTC" }, async () => {
  const yesterday = dayKey(new Date(Date.now() - 24 * 3600_000));
  await aggregateDay(db, yesterday);
});
