import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

import { ServerConfig } from "../config/serverConfig";

/**
 * Daily AI usage per user: `usage/{uid}/days/{yyyy-MM-dd}` (server-only).
 *   requests        credits consumed today
 *   freeTasks       zero-credit tasks today (separately capped)
 *   rewardedAds     rewarded ads redeemed today
 *   bonus           credits earned from rewarded ads today
 *   inputTokens / outputTokens / estCostUsd
 * Plus `usage/{uid}` lifetime totals (estimated_ai_cost_per_user).
 */
export interface DayUsage {
  requests: number;
  freeTasks: number;
  rewardedAds: number;
  bonus: number;
}

export interface CreditsView {
  used: number;
  limit: number;
  bonus: number;
  premium: boolean;
  rewardedRemaining: number;
}

export const FREE_TASKS_PER_DAY = 40;

export type CreditDecision =
  | { ok: true; next: DayUsage }
  | { ok: false; reason: "quota" | "fair_use" | "free_task_cap" };

/** Pure credit check used inside the transaction (unit-tested). */
export function decideCredit(day: DayUsage, cfg: ServerConfig, premium: boolean, cost: number): CreditDecision {
  if (cost === 0) {
    if (day.freeTasks >= FREE_TASKS_PER_DAY) return { ok: false, reason: "free_task_cap" };
    return { ok: true, next: { ...day, freeTasks: day.freeTasks + 1 } };
  }
  if (premium) {
    if (day.requests + cost > cfg.premiumDailyFairUse) return { ok: false, reason: "fair_use" };
  } else if (day.requests + cost > cfg.dailyFreeAiLimit + day.bonus) {
    return { ok: false, reason: "quota" };
  }
  return { ok: true, next: { ...day, requests: day.requests + cost } };
}

export type RewardDecision = { ok: true; next: DayUsage } | { ok: false };

/** Rewarded ads add credits, capped per day by `rewarded_ai_limit`. */
export function decideReward(day: DayUsage, cfg: ServerConfig, premium: boolean): RewardDecision {
  if (premium || day.rewardedAds >= cfg.rewardedAiLimit) return { ok: false };
  return { ok: true, next: { ...day, rewardedAds: day.rewardedAds + 1, bonus: day.bonus + cfg.rewardedCreditsPerAd } };
}

export function creditsView(day: DayUsage, cfg: ServerConfig, premium: boolean): CreditsView {
  return {
    used: day.requests,
    limit: premium ? cfg.premiumDailyFairUse : cfg.dailyFreeAiLimit,
    bonus: day.bonus,
    premium,
    rewardedRemaining: premium ? 0 : Math.max(0, cfg.rewardedAiLimit - day.rewardedAds),
  };
}

/** Sliding one-minute window rate limit decision (pure). */
export function decideRate(state: { windowStart: number; count: number } | undefined, now: number, perMinute: number) {
  if (!state || now - state.windowStart >= 60_000) return { ok: true, next: { windowStart: now, count: 1 } };
  if (state.count >= perMinute) return { ok: false, next: state };
  return { ok: true, next: { windowStart: state.windowStart, count: state.count + 1 } };
}

function readDay(data: FirebaseFirestore.DocumentData | undefined): DayUsage {
  const n = (k: string) => (typeof data?.[k] === "number" ? (data[k] as number) : 0);
  return { requests: n("requests"), freeTasks: n("freeTasks"), rewardedAds: n("rewardedAds"), bonus: n("bonus") };
}

export class UsageStore {
  constructor(private readonly db: Firestore) {}

  private dayRef(uid: string, day: string) {
    return this.db.collection("usage").doc(uid).collection("days").doc(day);
  }

  async isPremium(uid: string, now = new Date()): Promise<boolean> {
    const snap = await this.db.collection("entitlements").doc(uid).get();
    const d = snap.data();
    if (!d?.premium) return false;
    const exp = d.expiresAt instanceof Timestamp ? d.expiresAt.toDate() : null;
    return !exp || exp > now;
  }

  async view(uid: string, day: string, cfg: ServerConfig, premium: boolean): Promise<CreditsView> {
    return creditsView(readDay((await this.dayRef(uid, day).get()).data()), cfg, premium);
  }

  /**
   * Atomically applies the rate limit and reserves credits. Returns the
   * updated view, or the reason it was refused.
   */
  async reserve(
    uid: string,
    day: string,
    cfg: ServerConfig,
    premium: boolean,
    cost: number,
    now = Date.now(),
  ): Promise<{ ok: true; view: CreditsView } | { ok: false; reason: string; view: CreditsView }> {
    const rateRef = this.db.collection("rate_limits").doc(uid);
    const dayRef = this.dayRef(uid, day);
    return this.db.runTransaction(async (tx) => {
      const [rateSnap, daySnap] = await Promise.all([tx.get(rateRef), tx.get(dayRef)]);
      const current = readDay(daySnap.data());
      const rs = rateSnap.data() as { windowStart: number; count: number } | undefined;
      const rate = decideRate(rs, now, cfg.aiRequestsPerMinute);
      if (!rate.ok) return { ok: false as const, reason: "rate_limited", view: creditsView(current, cfg, premium) };
      const d = decideCredit(current, cfg, premium, cost);
      tx.set(rateRef, rate.next);
      if (!d.ok) return { ok: false as const, reason: d.reason, view: creditsView(current, cfg, premium) };
      tx.set(dayRef, { ...d.next, premium, day, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      return { ok: true as const, view: creditsView(d.next, cfg, premium) };
    });
  }

  /** Gives back a reserved credit when the AI call failed. */
  async refund(uid: string, day: string, cost: number): Promise<void> {
    await this.dayRef(uid, day).set(
      cost === 0 ? { freeTasks: FieldValue.increment(-1) } : { requests: FieldValue.increment(-cost) },
      { merge: true },
    );
  }

  /** Records tokens and estimated cost (per day and lifetime). */
  async record(uid: string, day: string, tokensIn: number, tokensOut: number, costUsd: number, model: string): Promise<void> {
    const batch = this.db.batch();
    batch.set(
      this.dayRef(uid, day),
      {
        inputTokens: FieldValue.increment(tokensIn),
        outputTokens: FieldValue.increment(tokensOut),
        estCostUsd: FieldValue.increment(costUsd),
        [`models.${model.replace(/[^\w-]/g, "_")}`]: FieldValue.increment(1),
        day,
      },
      { merge: true },
    );
    batch.set(
      this.db.collection("usage").doc(uid),
      {
        estimated_ai_cost_per_user: FieldValue.increment(costUsd),
        totalRequests: FieldValue.increment(1),
        lastActiveDay: day,
      },
      { merge: true },
    );
    await batch.commit();
  }

  async grantReward(uid: string, day: string, cfg: ServerConfig, premium: boolean): Promise<{ granted: boolean; view: CreditsView }> {
    const ref = this.dayRef(uid, day);
    return this.db.runTransaction(async (tx) => {
      const current = readDay((await tx.get(ref)).data());
      const d = decideReward(current, cfg, premium);
      if (!d.ok) return { granted: false, view: creditsView(current, cfg, premium) };
      tx.set(ref, { ...d.next, day, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      return { granted: true, view: creditsView(d.next, cfg, premium) };
    });
  }
}
