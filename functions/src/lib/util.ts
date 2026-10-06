import { HttpsError } from "firebase-functions/v2/https";

/** Calendar day (yyyy-MM-dd) in the user's IANA time zone; UTC if invalid. */
export function dayKey(now: Date, timeZone?: unknown): string {
  const tz = typeof timeZone === "string" && isValidTimeZone(timeZone) ? timeZone : "UTC";
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? "00";
  return `${get("year")}-${get("month")}-${get("day")}`;
}

export function isValidTimeZone(tz: string): boolean {
  if (tz.length > 64) return false;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

export function requireAuth(auth: { uid: string } | undefined): string {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Sign in required.");
  return auth.uid;
}

export function asRecord(v: unknown): Record<string, unknown> {
  return v && typeof v === "object" && !Array.isArray(v) ? (v as Record<string, unknown>) : {};
}

export function str(v: unknown, max: number): string {
  if (typeof v !== "string") return "";
  // Strip control characters (except newlines/tabs) and cap length.
  return v.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "").slice(0, max);
}

/** Stable JSON (sorted keys) for cache keys. */
export function stableStringify(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(stableStringify).join(",")}]`;
  if (v && typeof v === "object") {
    const o = v as Record<string, unknown>;
    return `{${Object.keys(o)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${stableStringify(o[k])}`)
      .join(",")}}`;
  }
  return JSON.stringify(v ?? null);
}
