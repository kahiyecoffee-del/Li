import { generateKeyPairSync, createSign } from "node:crypto";

import { describe, expect, it, vi } from "vitest";

import { verifySsv } from "../src/ads/ssv";
import { interpretSubscription } from "../src/billing/play";
import { dayKey } from "../src/lib/util";
import { summarize } from "../src/metrics/aggregate";

describe("AdMob SSV", () => {
  const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = publicKey.export({ type: "spki", format: "pem" }).toString();
  const fetchKeys = vi.fn(async () => new Response(JSON.stringify({ keys: [{ keyId: 42, pem }] })));

  function signed(message: string) {
    const s = createSign("SHA256");
    s.update(message);
    const sig = s.sign(privateKey).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
    return `${message}&signature=${sig}&key_id=42`;
  }

  it("accepts a correctly signed callback", async () => {
    const q = signed("ad_network=1&ad_unit=2&custom_data=aiCredits&reward_amount=1&reward_item=credit&timestamp=1&transaction_id=tx1&user_id=u1");
    expect(await verifySsv(q, fetchKeys as unknown as typeof fetch)).toEqual({ transactionId: "tx1", userId: "u1", customData: "aiCredits" });
  });

  it("rejects tampered or unsigned callbacks", async () => {
    const q = signed("transaction_id=tx1&user_id=u1").replace("user_id=u1", "user_id=attacker");
    expect(await verifySsv(q, fetchKeys as unknown as typeof fetch)).toBeNull();
    expect(await verifySsv("transaction_id=tx1&user_id=u1", fetchKeys as unknown as typeof fetch)).toBeNull();
  });
});

describe("Play subscriptions", () => {
  it("active, grace and expired states", () => {
    const future = new Date(Date.now() + 86400_000).toISOString();
    const past = new Date(Date.now() - 86400_000).toISOString();
    const active = interpretSubscription({ subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: [{ productId: "lifeos_premium_monthly", expiryTime: future, autoRenewingPlan: { autoRenewEnabled: true } }] });
    expect(active).toMatchObject({ active: true, productId: "lifeos_premium_monthly", autoRenewing: true });
    expect(interpretSubscription({ subscriptionState: "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", lineItems: [{ expiryTime: future }] }).active).toBe(true);
    expect(interpretSubscription({ subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: [{ expiryTime: past }] }).active).toBe(false);
    expect(interpretSubscription({ subscriptionState: "SUBSCRIPTION_STATE_CANCELED", lineItems: [{ expiryTime: future }] }).active).toBe(false);
  });
});

describe("utils & metrics", () => {
  it("day key follows the user's time zone", () => {
    const t = new Date("2026-06-10T22:30:00Z");
    expect(dayKey(t, "UTC")).toBe("2026-06-10");
    expect(dayKey(t, "Europe/Istanbul")).toBe("2026-06-11");
    expect(dayKey(t, "Not/AZone")).toBe("2026-06-10");
  });

  it("summarizes AI cost per active user", () => {
    const s = summarize([{ requests: 3, estCostUsd: 0.01, rewardedAds: 1 }, { requests: 0, rewardedAds: 0 }, { requests: 1, estCostUsd: 0.03, premium: true }]);
    expect(s.aiActiveUsers).toBe(2);
    expect(s.aiCostPerActiveUser).toBeCloseTo(0.02);
    expect(s.rewardedAdsPerUser).toBe(0.5);
  });
});
