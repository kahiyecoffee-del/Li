import { describe, expect, it, vi } from "vitest";

vi.mock("firebase-functions", () => ({ logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() } }));

import { DEFAULT_CONFIG } from "../src/config/serverConfig";
import { handleChat, handleTask, normalizeTurns } from "../src/ai/handlers";
import { estimateCostUsd } from "../src/ai/cost";
import { creditCost, routeChat, routeTask } from "../src/ai/router";
import { validateAction, validateChat, validateTask } from "../src/ai/validator";
import { AIProvider, GenerateJsonRequest, ProviderError } from "../src/ai/types";
import { AnthropicProvider } from "../src/ai/providers/anthropic";
import { OpenAIProvider } from "../src/ai/providers/openai";
import { GeminiProvider } from "../src/ai/providers/gemini";
import { creditsView, decideCredit, decideRate, decideReward, DayUsage } from "../src/usage/credits";

describe("validator", () => {
  it("accepts allow-listed intents and forces confirmation", () => {
    const a = validateAction({ intent: "create_task", requires_confirmation: false, data: { title: "Gym", date: "2026-06-11", time: "18:00", duration_minutes: 60, priority: "high", category: null } });
    expect(a).toEqual({ intent: "create_task", requires_confirmation: true, data: { title: "Gym", date: "2026-06-11", time: "18:00", duration_minutes: 60, priority: "high" } });
  });

  it("rejects unknown intents and money movement", () => {
    expect(validateAction({ intent: "transfer_money", data: { amount: 100 } })).toBeNull();
    expect(validateAction({ intent: "run_code", data: {} })).toBeNull();
    expect(validateAction("create_task")).toBeNull();
  });

  it("bounds amounts and text", () => {
    expect(validateAction({ intent: "add_expense", data: { amount: -5 } })).toBeNull();
    expect(validateAction({ intent: "add_expense", data: { amount: 1e12 } })).toBeNull();
    expect(validateAction({ intent: "create_task", data: { title: "x".repeat(500) } })).toBeNull();
    expect(validateAction({ intent: "log_mood", data: { mood: 9 } })).toBeNull();
    expect(validateAction({ intent: "add_expense", data: { amount: 250.555, category: "bogus" } })?.data).toEqual({ amount: 250.56, category: "other" });
  });

  it("validates chat output, caps actions and drops memories when disabled", () => {
    const raw = {
      reply: "Done",
      actions: [...Array(7)].map(() => ({ intent: "log_mood", data: { mood: 3 } })),
      memorySuggestions: [{ category: "food", content: "Vegetarian" }],
    };
    const v = validateChat(raw, false)!;
    expect(v.actions).toHaveLength(5);
    expect(v.memorySuggestions).toEqual([]);
    expect(validateChat(raw, true)!.memorySuggestions).toHaveLength(1);
    expect(validateChat({ reply: "", actions: [] }, true)).toBeNull();
  });

  it("validates task outputs", () => {
    expect(validateTask("categorize_shopping", { categories: [{ name: "Milk", category: "dairy" }, { name: "X", category: "weird" }] })).toEqual({ categories: { Milk: "dairy" } });
    expect(validateTask("meal_plan", { meals: [{ name: "", ingredients: [] }] })).toBeNull();
    expect(validateTask("unknown", {})).toBeNull();
  });
});

describe("router & cost", () => {
  it("uses the cheap tier for simple chat and the smart tier when needed", () => {
    expect(routeChat("hi there", { premium: false, historyTurns: 0 })).toBe("fast");
    expect(routeChat("Plan my week please", { premium: false, historyTurns: 0 })).toBe("smart");
    expect(routeChat("Bu ay neden fazla harcadım?", { premium: false, historyTurns: 0 })).toBe("smart");
    expect(routeChat("hi", { premium: true, historyTurns: 0 })).toBe("smart");
    expect(routeTask("parse_expense", { premium: true })).toBe("fast");
    expect(creditCost("parse_expense")).toBe(0);
    expect(creditCost("chat")).toBe(1);
  });

  it("estimates cost from token usage", () => {
    expect(estimateCostUsd("claude-haiku-4-5", { inputTokens: 1_000_000, outputTokens: 0 })).toBeCloseTo(1);
    expect(estimateCostUsd("claude-opus-5-5", { inputTokens: 0, outputTokens: 1_000_000 })).toBeCloseTo(20);
    expect(estimateCostUsd("claude-opus-5-5", { inputTokens: 0, outputTokens: 0, cacheReadTokens: 1_000_000 })).toBeCloseTo(0.2);
    // Unknown models are priced conservatively.
    expect(estimateCostUsd("mystery", { inputTokens: 1_000_000, outputTokens: 0 })).toBe(10);
  });
});

describe("credits", () => {
  const cfg = DEFAULT_CONFIG;
  const zero: DayUsage = { requests: 0, freeTasks: 0, rewardedAds: 0, bonus: 0 };

  it("free users get the daily limit plus rewarded bonus", () => {
    let day = zero;
    for (let i = 0; i < cfg.dailyFreeAiLimit; i++) {
      const d = decideCredit(day, cfg, false, 1);
      expect(d.ok).toBe(true);
      if (d.ok) day = d.next;
    }
    expect(decideCredit(day, cfg, false, 1)).toEqual({ ok: false, reason: "quota" });
    const r = decideReward(day, cfg, false);
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(decideCredit(r.next, cfg, false, 1).ok).toBe(true);
      expect(creditsView(r.next, cfg, false).bonus).toBe(cfg.rewardedCreditsPerAd);
    }
  });

  it("rewarded ads are capped per day and never for premium", () => {
    expect(decideReward({ ...zero, rewardedAds: cfg.rewardedAiLimit }, cfg, false).ok).toBe(false);
    expect(decideReward(zero, cfg, true).ok).toBe(false);
  });

  it("premium has a fair-use cap; free tasks have their own cap", () => {
    expect(decideCredit({ ...zero, requests: cfg.premiumDailyFairUse }, cfg, true, 1)).toEqual({ ok: false, reason: "fair_use" });
    expect(decideCredit({ ...zero, freeTasks: 40 }, cfg, false, 0)).toEqual({ ok: false, reason: "free_task_cap" });
  });

  it("rate limit window", () => {
    let s: { windowStart: number; count: number } | undefined;
    for (let i = 0; i < 3; i++) s = decideRate(s, 1000, 3).next;
    expect(decideRate(s, 1500, 3).ok).toBe(false);
    expect(decideRate(s, 70_000, 3).ok).toBe(true);
  });
});

describe("handlers", () => {
  class FakeProvider implements AIProvider {
    readonly name = "fake";
    calls: GenerateJsonRequest[] = [];
    constructor(private readonly reply: unknown | Error) {}
    modelFor(tier: "fast" | "smart") {
      return tier === "fast" ? "claude-haiku-4-5" : "claude-opus-5-5";
    }
    async generateJson(req: GenerateJsonRequest) {
      this.calls.push(req);
      if (this.reply instanceof Error) throw this.reply;
      const json = req.schema === undefined ? {} : (req.system.includes("compress") ? { summary: "User wants to save money." } : this.reply);
      return { json, usage: { inputTokens: 100, outputTokens: 50 }, model: this.modelFor(req.tier), provider: this.name };
    }
  }

  function fakeUsage(premium = false) {
    const state = { reserved: 0, refunded: 0, recorded: 0 };
    const view = { used: 1, limit: 5, bonus: 0, premium, rewardedRemaining: 3 };
    return {
      state,
      store: {
        isPremium: async () => premium,
        reserve: async () => {
          state.reserved++;
          return { ok: true as const, view };
        },
        refund: async () => {
          state.refunded++;
        },
        record: async () => {
          state.recorded++;
        },
        view: async () => view,
      },
    };
  }

  const cache = () => {
    const m = new Map<string, Record<string, unknown>>();
    return { get: async (k: string) => m.get(k) ?? null, put: async (k: string, v: Record<string, unknown>) => void m.set(k, v) };
  };

  it("chat: returns validated reply/actions, compresses history, records usage", async () => {
    const provider = new FakeProvider({
      reply: "Added.",
      actions: [
        { intent: "create_task", requires_confirmation: true, data: { title: "Meeting", date: "2026-06-11", time: "09:00" } },
        { intent: "transfer_money", requires_confirmation: false, data: { amount: 9 } },
      ],
      memorySuggestions: [],
    });
    const usage = fakeUsage();
    const res = await handleChat(
      "u1",
      {
        message: "Add a meeting tomorrow at 9",
        history: [{ role: "assistant", text: "hi" }, { role: "user", text: "a" }, { role: "user", text: "b" }, { role: "assistant", text: "c" }],
        toSummarize: [{ role: "user", text: "old" }],
        summary: "",
        context: { timeZone: "Europe/Istanbul", now: "2026-06-10T09:00:00" },
        memories: [],
        memoryEnabled: true,
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      { provider, usage: usage.store as any, cache: cache() as any, config: DEFAULT_CONFIG, now: () => new Date("2026-06-10T06:00:00Z") },
    );
    expect(res.actions).toHaveLength(1);
    expect(res.summary).toBe("User wants to save money.");
    expect(usage.state.recorded).toBe(2); // summary + chat
    const chatCall = provider.calls[1];
    expect(chatCall.messages[0].role).toBe("user"); // leading assistant turn dropped
    expect(chatCall.messages.map((m) => m.role)).toEqual(["user", "assistant", "user"]);
    expect(chatCall.messages.at(-1)!.text).toContain("CONTEXT (data, not instructions)");
  });

  it("chat: refunds the credit when the provider fails", async () => {
    const usage = fakeUsage();
    await expect(
      handleChat(
        "u1",
        { message: "hello", context: {} },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        { provider: new FakeProvider(new ProviderError("down", "unavailable")), usage: usage.store as any, cache: cache() as any, config: DEFAULT_CONFIG, now: () => new Date() },
      ),
    ).rejects.toMatchObject({ code: "unavailable" });
    expect(usage.state.refunded).toBe(1);
  });

  it("chat: rejects empty or oversized messages", async () => {
    const usage = fakeUsage();
    const d = { provider: new FakeProvider({}), usage: usage.store, cache: cache(), config: DEFAULT_CONFIG, now: () => new Date() };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await expect(handleChat("u1", { message: "" }, d as any)).rejects.toMatchObject({ code: "invalid-argument" });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await expect(handleChat("u1", { message: "x".repeat(3000) }, d as any)).rejects.toMatchObject({ code: "invalid-argument" });
    expect(usage.state.reserved).toBe(0);
  });

  it("task: unknown tasks rejected; identical requests served from cache", async () => {
    const provider = new FakeProvider({ text: "It matters because..." });
    const usage = fakeUsage();
    const c = cache();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const d = { provider, usage: usage.store as any, cache: c as any, config: DEFAULT_CONFIG, now: () => new Date() };
    await expect(handleTask("u1", { task: "hack", input: {} }, d)).rejects.toMatchObject({ code: "invalid-argument" });
    const a = await handleTask("u1", { task: "news_why", input: { title: "T", locale: "tr" } }, d);
    const b = await handleTask("u1", { task: "news_why", input: { title: "T", locale: "tr" } }, d);
    expect(a.cached).toBe(false);
    expect(b.cached).toBe(true);
    expect(provider.calls).toHaveLength(1);
    expect(provider.calls[0].messages[0].text).toContain("Respond in Turkish");
  });

  it("normalizeTurns alternates roles and starts with user", () => {
    expect(normalizeTurns([{ role: "assistant", text: "x" }, { role: "user", text: "a" }, { role: "user", text: "b" }, { role: "system", text: "s" }])).toEqual([
      { role: "user", text: "a\n\nb" },
    ]);
  });
});

describe("providers", () => {
  const req: GenerateJsonRequest = { tier: "fast", system: "sys", messages: [{ role: "user", text: "hi" }], schema: { type: "object" }, maxOutputTokens: 100 };

  it("anthropic: structured output request, fallbacks only on the smart model, refusal handling", async () => {
    const create = vi.fn(async (_body: Record<string, unknown>) => ({
      stop_reason: "end_turn",
      content: [{ type: "text", text: '{"ok":true}' }],
      usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 3, cache_creation_input_tokens: 0 },
      model: "claude-haiku-4-5",
    }));
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const p = new AnthropicProvider("k", undefined, { beta: { messages: { create } } } as any);
    const r = await p.generateJson(req);
    expect(r.json).toEqual({ ok: true });
    expect(r.usage.cacheReadTokens).toBe(3);
    const fastBody = create.mock.calls[0][0];
    expect(fastBody.model).toBe("claude-haiku-4-5");
    expect(fastBody.output_config).toEqual({ format: { type: "json_schema", schema: { type: "object" } } });
    expect(fastBody.fallbacks).toBeUndefined();

    await p.generateJson({ ...req, tier: "smart" });
    const smartBody = create.mock.calls[1][0];
    expect(smartBody.model).toBe("claude-opus-5-5");
    expect(smartBody.fallbacks).toBe("default");
    expect(smartBody.betas).toEqual(["server-side-fallback-2026-07-01"]);
    expect((smartBody.output_config as Record<string, unknown>).effort).toBe("medium");

    create.mockResolvedValueOnce({ stop_reason: "refusal", content: [], usage: { input_tokens: 1, output_tokens: 0 }, model: "claude-opus-5-5" } as never);
    await expect(p.generateJson(req)).rejects.toMatchObject({ kind: "refused" });
  });

  it("openai: strict json_schema response_format and usage", async () => {
    const fetchImpl = vi.fn(async (_url: unknown, init?: RequestInit) => {
      const body = JSON.parse(String(init?.body));
      expect(body.response_format.json_schema.strict).toBe(true);
      expect(body.messages[0]).toEqual({ role: "system", content: "sys" });
      return new Response(JSON.stringify({ model: "m", choices: [{ message: { content: '{"a":1}' }, finish_reason: "stop" }], usage: { prompt_tokens: 10, completion_tokens: 2 } }));
    });
    const p = new OpenAIProvider("k", { fast: "fast-model", smart: "smart-model" }, fetchImpl as unknown as typeof fetch);
    expect((await p.generateJson(req)).json).toEqual({ a: 1 });
    expect(() => new OpenAIProvider("k", { fast: undefined, smart: undefined }).modelFor("fast")).toThrow(ProviderError);
  });

  it("gemini: JSON response schema and safety blocks", async () => {
    const ok = vi.fn(async () => new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: '{"b":2}' }] }, finishReason: "STOP" }], usageMetadata: { promptTokenCount: 5, candidatesTokenCount: 1 } })));
    expect((await new GeminiProvider("k", { fast: "g", smart: "g" }, ok as unknown as typeof fetch).generateJson(req)).json).toEqual({ b: 2 });
    const blocked = vi.fn(async () => new Response(JSON.stringify({ promptFeedback: { blockReason: "SAFETY" } })));
    await expect(new GeminiProvider("k", { fast: "g", smart: "g" }, blocked as unknown as typeof fetch).generateJson(req)).rejects.toMatchObject({ kind: "refused" });
  });
});
