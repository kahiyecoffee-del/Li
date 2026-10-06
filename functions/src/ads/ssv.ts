import { createVerify } from "node:crypto";

/**
 * AdMob rewarded-ad server-side verification (SSV).
 * Google signs the callback query string with ECDSA (SHA-256); public keys
 * are published at VERIFIER_KEYS_URL. https://developers.google.com/admob/android/ssv
 */
export const VERIFIER_KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json";

interface VerifierKey {
  keyId: number;
  pem: string;
}

let keyCache: { at: number; keys: VerifierKey[] } | undefined;

async function verifierKeys(fetchImpl: typeof fetch, now: number): Promise<VerifierKey[]> {
  if (keyCache && now - keyCache.at < 24 * 3600_000) return keyCache.keys;
  const res = await fetchImpl(VERIFIER_KEYS_URL, { signal: AbortSignal.timeout(10_000) });
  const body = (await res.json()) as { keys?: { keyId: number; pem: string }[] };
  keyCache = { at: now, keys: body.keys ?? [] };
  return keyCache.keys;
}

export interface SsvPayload {
  transactionId: string;
  userId: string;
  customData: string;
}

/**
 * Verifies the raw query string ("ad_network=…&…&signature=…&key_id=…").
 * The signed content is everything before "&signature=". Returns the
 * payload if valid, otherwise null.
 */
export async function verifySsv(rawQuery: string, fetchImpl: typeof fetch = fetch, now = Date.now()): Promise<SsvPayload | null> {
  const sigIndex = rawQuery.indexOf("&signature=");
  if (sigIndex < 0) return null;
  const message = rawQuery.slice(0, sigIndex);
  const params = new URLSearchParams(rawQuery);
  const signature = params.get("signature");
  const keyId = Number(params.get("key_id"));
  if (!signature || !Number.isFinite(keyId)) return null;
  const key = (await verifierKeys(fetchImpl, now)).find((k) => k.keyId === keyId);
  if (!key) return null;
  const verifier = createVerify("SHA256");
  verifier.update(message);
  const sig = Buffer.from(signature.replace(/-/g, "+").replace(/_/g, "/"), "base64");
  if (!verifier.verify(key.pem, sig)) return null;
  const transactionId = params.get("transaction_id") ?? "";
  const userId = params.get("user_id") ?? "";
  if (!transactionId || !userId) return null;
  return { transactionId, userId, customData: params.get("custom_data") ?? "" };
}
