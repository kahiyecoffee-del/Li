import { getRemoteConfig } from "firebase-admin/remote-config";
import { logger } from "firebase-functions";

/**
 * Remote Config values enforced server-side. Keys and defaults MUST match
 * the client (lib/services/config/remote_config_service.dart) so the app's
 * display and the server's enforcement agree.
 */
export interface ServerConfig {
  dailyFreeAiLimit: number;
  rewardedAiLimit: number;
  rewardedCreditsPerAd: number;
  premiumDailyFairUse: number;
  aiRequestsPerMinute: number;
  premiumFeatures: string[];
}

export const DEFAULT_CONFIG: ServerConfig = {
  dailyFreeAiLimit: 5,
  rewardedAiLimit: 3,
  rewardedCreditsPerAd: 2,
  premiumDailyFairUse: 200,
  aiRequestsPerMinute: 8,
  premiumFeatures: [
    "unlimited_ai",
    "advanced_score",
    "advanced_analytics",
    "no_ads",
    "advanced_planning",
    "advanced_finance",
    "unlimited_meals",
    "ai_memory_unlimited",
    "monthly_report",
  ],
};

let cache: { at: number; value: ServerConfig } | undefined;
const TTL_MS = 5 * 60 * 1000;

/** Reads the Remote Config server template (cached 5 min), falling back to defaults. */
export async function getServerConfig(now = Date.now()): Promise<ServerConfig> {
  if (cache && now - cache.at < TTL_MS) return cache.value;
  let value = DEFAULT_CONFIG;
  try {
    const template = await getRemoteConfig().getServerTemplate({
      defaultConfig: {
        daily_free_ai_limit: DEFAULT_CONFIG.dailyFreeAiLimit,
        rewarded_ai_limit: DEFAULT_CONFIG.rewardedAiLimit,
        rewarded_credits_per_ad: DEFAULT_CONFIG.rewardedCreditsPerAd,
        premium_daily_fair_use: DEFAULT_CONFIG.premiumDailyFairUse,
        ai_requests_per_minute: DEFAULT_CONFIG.aiRequestsPerMinute,
        premium_features: JSON.stringify(DEFAULT_CONFIG.premiumFeatures),
      },
    });
    const c = template.evaluate();
    value = {
      dailyFreeAiLimit: clampInt(c.getNumber("daily_free_ai_limit"), 0, 1000),
      rewardedAiLimit: clampInt(c.getNumber("rewarded_ai_limit"), 0, 50),
      rewardedCreditsPerAd: clampInt(c.getNumber("rewarded_credits_per_ad"), 0, 20),
      premiumDailyFairUse: clampInt(c.getNumber("premium_daily_fair_use"), 1, 10000),
      aiRequestsPerMinute: clampInt(c.getNumber("ai_requests_per_minute"), 1, 120),
      premiumFeatures: parseList(c.getString("premium_features"), DEFAULT_CONFIG.premiumFeatures),
    };
  } catch (e) {
    logger.warn("Remote Config server template unavailable; using defaults", e);
  }
  cache = { at: now, value };
  return value;
}

function clampInt(v: number, min: number, max: number): number {
  return Number.isFinite(v) ? Math.min(max, Math.max(min, Math.round(v))) : min;
}

function parseList(s: string, fallback: string[]): string[] {
  try {
    const v: unknown = JSON.parse(s);
    return Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : fallback;
  } catch {
    return fallback;
  }
}
