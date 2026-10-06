import { readFileSync } from "node:fs";

import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, deleteDoc, serverTimestamp, setLogLevel } from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

setLogLevel("error");
let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-lifeos",
    firestore: { rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8") },
  });
});
afterAll(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const task = (id, extra = {}) => ({ id, updatedAt: 1, deleted: false, _serverTs: serverTimestamp(), title: "Gym", ...extra });

describe("user data", () => {
  it("owner can write and read synced records", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(setDoc(doc(db, "users/alice/tasks/t1"), task("t1")));
    await assertSucceeds(getDoc(doc(db, "users/alice/tasks/t1")));
  });

  it("other users cannot read or write", async () => {
    const bob = env.authenticatedContext("bob").firestore();
    await assertFails(getDoc(doc(bob, "users/alice/tasks/t1")));
    await assertFails(setDoc(doc(bob, "users/alice/tasks/t1"), task("t1")));
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, "users/alice/tasks/t1")));
  });

  it("requires sync metadata and a real server timestamp", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "users/alice/tasks/t1"), { ...task("t1"), _serverTs: new Date(0) }));
    await assertFails(setDoc(doc(db, "users/alice/tasks/t1"), task("other-id")));
    const { updatedAt: _u, ...noUpdated } = task("t1");
    await assertFails(setDoc(doc(db, "users/alice/tasks/t1"), noUpdated));
  });

  it("rejects unknown collections and invalid bodies", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "users/alice/secrets/x"), task("x")));
    await assertFails(setDoc(doc(db, "users/alice/journal_entries/j"), task("j"))); // journal never syncs
    await assertFails(setDoc(doc(db, "users/alice/mood_logs/2026-06-10"), task("2026-06-10", { mood: 9 })));
    await assertFails(setDoc(doc(db, "users/alice/transactions/x"), task("x", { amountMinor: -5, type: "expense", currency: "TRY" })));
    await assertSucceeds(setDoc(doc(db, "users/alice/transactions/x"), task("x", { amountMinor: 25000, type: "expense", currency: "TRY" })));
  });

  it("deletes only as tombstones", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(setDoc(doc(db, "users/alice/tasks/t1"), task("t1")));
    await assertFails(deleteDoc(doc(db, "users/alice/tasks/t1")));
    await assertSucceeds(setDoc(doc(db, "users/alice/tasks/t1"), { id: "t1", updatedAt: 2, deleted: true, _serverTs: serverTimestamp() }));
  });
});

describe("server-only collections", () => {
  it("entitlements are readable by the owner but never client-writable", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), "entitlements/alice"), { premium: true }));
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(getDoc(doc(db, "entitlements/alice")));
    await assertFails(setDoc(doc(db, "entitlements/alice"), { premium: true }));
    await assertFails(getDoc(doc(env.authenticatedContext("bob").firestore(), "entitlements/alice")));
  });

  it("usage, caches and metrics are inaccessible", async () => {
    const db = env.authenticatedContext("alice").firestore();
    for (const path of ["usage/alice", "usage/alice/days/2026-06-10", "rate_limits/alice", "ai_cache/x", "metrics_daily/2026-06-10", "purchases/x"]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(setDoc(doc(db, path), { requests: 0 }));
    }
  });

  it("devices: owner may register a token with allowed fields only", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(setDoc(doc(db, "users/alice/devices/tok"), { platform: "android", locale: "tr", updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, "users/alice/devices/tok2"), { platform: "android", premium: true }));
  });
});
