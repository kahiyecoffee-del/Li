import { createHash } from "node:crypto";

import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

import { stableStringify } from "../lib/util";

/**
 * Response cache for deterministic tasks (not chat): identical inputs to the
 * same model and prompt version reuse the previous answer for 24h. Keys are
 * hashes, so the cache holds no readable input. Collection `ai_cache` is
 * server-only; configure a Firestore TTL policy on `expiresAt`.
 */
export class AiCache {
  constructor(private readonly db: Firestore, private readonly ttlMs = 24 * 3600 * 1000) {}

  static key(parts: unknown): string {
    return createHash("sha256").update(stableStringify(parts)).digest("hex");
  }

  async get(key: string, now = Date.now()): Promise<Record<string, unknown> | null> {
    const snap = await this.db.collection("ai_cache").doc(key).get();
    const d = snap.data();
    if (!d || !(d.expiresAt instanceof Timestamp) || d.expiresAt.toMillis() < now) return null;
    return (d.result as Record<string, unknown>) ?? null;
  }

  async put(key: string, result: Record<string, unknown>, now = Date.now()): Promise<void> {
    await this.db.collection("ai_cache").doc(key).set({
      result,
      expiresAt: Timestamp.fromMillis(now + this.ttlMs),
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}
