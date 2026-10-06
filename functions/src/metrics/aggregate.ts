import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

/**
 * Daily monetization/cost metrics from server-side usage (metrics_daily/{day}):
 *   aiActiveUsers, aiRequests, estimatedAiCostUsd, aiCostPerActiveUser,
 *   rewardedAdsRedeemed, rewardedAdsPerUser, premiumActiveUsers.
 * Revenue metrics (ARPU, ARPPU, eCPM, LTV, churn) need AdMob + Play revenue;
 * see docs/MONETIZATION.md for the BigQuery export queries.
 */
export interface DayRow {
  requests?: number;
  estCostUsd?: number;
  rewardedAds?: number;
  premium?: boolean;
}

export function summarize(rows: DayRow[]) {
  const active = rows.filter((r) => (r.requests ?? 0) > 0 || (r.rewardedAds ?? 0) > 0);
  const cost = rows.reduce((s, r) => s + (r.estCostUsd ?? 0), 0);
  const rewarded = rows.reduce((s, r) => s + (r.rewardedAds ?? 0), 0);
  return {
    aiActiveUsers: active.length,
    aiRequests: rows.reduce((s, r) => s + (r.requests ?? 0), 0),
    estimatedAiCostUsd: Math.round(cost * 10000) / 10000,
    aiCostPerActiveUser: active.length ? Math.round((cost / active.length) * 10000) / 10000 : 0,
    rewardedAdsRedeemed: rewarded,
    rewardedAdsPerUser: active.length ? Math.round((rewarded / active.length) * 100) / 100 : 0,
    premiumUsersUsingAi: rows.filter((r) => r.premium).length,
  };
}

export async function aggregateDay(db: Firestore, day: string): Promise<void> {
  const snap = await db.collectionGroup("days").where("day", "==", day).get();
  const rows = snap.docs.map((d) => d.data() as DayRow);
  const premiumActive = await db
    .collection("entitlements")
    .where("premium", "==", true)
    .where("expiresAt", ">", Timestamp.now())
    .count()
    .get();
  await db
    .collection("metrics_daily")
    .doc(day)
    .set({ day, ...summarize(rows), premiumActiveUsers: premiumActive.data().count, computedAt: FieldValue.serverTimestamp() });
}
