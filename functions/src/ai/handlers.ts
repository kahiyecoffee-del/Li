import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { ServerConfig } from "../config/serverConfig";
import { asRecord, dayKey, stableStringify, str } from "../lib/util";
import { CreditsView, UsageStore } from "../usage/credits";
import { AiCache } from "./cache";
import { estimateCostUsd } from "./cost";
import { chatContextBlock, chatSystem, PROMPT_VERSION, summarizeSystem, taskSystem, taskUserBlock } from "./prompts";
import { creditCost, outputBudget, routeChat, routeTask } from "./router";
import { CATEGORIZE_SCHEMA, CHAT_SCHEMA, MEAL_PLAN_SCHEMA, PARSE_EXPENSE_SCHEMA, SUMMARY_SCHEMA, TEXT_SCHEMA } from "./schemas";
import { AIProvider, ChatTurn, GenerateJsonResult, ProviderError } from "./types";
import { validateChat, validateTask } from "./validator";

export interface Deps {
  provider: AIProvider;
  usage: UsageStore;
  cache: AiCache;
  config: ServerConfig;
  now: () => Date;
}

const LIMITS = { message: 2000, turn: 4000, turns: 8, summary: 2000, contextBytes: 20_000, memories: 30, inputBytes: 8_000 };

export const TASK_SCHEMAS: Record<string, Record<string, unknown>> = {
  parse_expense: PARSE_EXPENSE_SCHEMA,
  categorize_shopping: CATEGORIZE_SCHEMA,
  meal_plan: MEAL_PLAN_SCHEMA,
  weekly_summary: TEXT_SCHEMA,
  monthly_summary: TEXT_SCHEMA,
  news_why: TEXT_SCHEMA,
};

/**
 * Makes turns valid for every provider: starts with a user turn, roles
 * alternate (consecutive same-role turns are merged), bounded length.
 */
export function normalizeTurns(raw: unknown, maxTurns = LIMITS.turns): ChatTurn[] {
  const turns: ChatTurn[] = [];
  for (const t of Array.isArray(raw) ? raw.slice(-maxTurns * 2) : []) {
    const o = asRecord(t);
    const role = o.role === "assistant" ? "assistant" : o.role === "user" ? "user" : null;
    const text = str(o.text, LIMITS.turn).trim();
    if (!role || !text) continue;
    const last = turns[turns.length - 1];
    if (last && last.role === role) last.text = `${last.text}\n\n${text}`;
    else turns.push({ role, text });
  }
  while (turns.length && turns[0].role !== "user") turns.shift();
  return turns.slice(-maxTurns);
}

function quotaError(reason: string, credits: CreditsView): HttpsError {
  return new HttpsError("resource-exhausted", reason === "rate_limited" ? "Too many requests." : "AI limit reached.", {
    reason,
    credits,
  });
}

function providerError(e: unknown): HttpsError {
  if (e instanceof ProviderError) {
    logger.warn("AI provider error", { kind: e.kind, message: e.message });
    if (e.kind === "rate_limited" || e.kind === "unavailable") return new HttpsError("unavailable", "AI temporarily unavailable.");
    if (e.kind === "refused") return new HttpsError("failed-precondition", "Request declined.", { reason: "refused" });
    if (e.kind === "bad_output") return new HttpsError("internal", "AI returned an invalid response.");
    return new HttpsError("internal", "AI is not configured.");
  }
  logger.error("Unexpected AI error", e);
  return new HttpsError("internal", "Unexpected error.");
}

async function recordUsage(deps: Deps, uid: string, day: string, r: GenerateJsonResult): Promise<void> {
  const cost = estimateCostUsd(r.model, r.usage);
  await deps.usage.record(
    uid,
    day,
    r.usage.inputTokens + (r.usage.cacheReadTokens ?? 0) + (r.usage.cacheWriteTokens ?? 0),
    r.usage.outputTokens,
    cost,
    r.model,
  );
}

export async function handleChat(uid: string, data: unknown, deps: Deps) {
  const d = asRecord(data);
  const message = str(d.message, LIMITS.message + 1).trim();
  if (!message || message.length > LIMITS.message) throw new HttpsError("invalid-argument", "Invalid message.");
  const context = asRecord(d.context);
  if (stableStringify(context).length > LIMITS.contextBytes) throw new HttpsError("invalid-argument", "Context too large.");
  const memories = (Array.isArray(d.memories) ? d.memories.slice(0, LIMITS.memories) : []).map((m) => {
    const o = asRecord(m);
    return { category: str(o.category, 20), content: str(o.content, 200) };
  });
  const memoryEnabled = d.memoryEnabled === true;
  const history = normalizeTurns(d.history);
  const toSummarize = normalizeTurns(d.toSummarize, 30);
  let summary = str(d.summary, LIMITS.summary);

  const now = deps.now();
  const day = dayKey(now, d.timeZone ?? context.timeZone);
  const premium = await deps.usage.isPremium(uid, now);
  const reserved = await deps.usage.reserve(uid, day, deps.config, premium, creditCost("chat"), now.getTime());
  if (!reserved.ok) throw quotaError(reserved.reason, reserved.view);

  try {
    // Conversation compression: fold turns leaving the window into the summary (cheap model).
    let newSummary: string | undefined;
    if (toSummarize.length > 0) {
      const s = await deps.provider.generateJson({
        tier: "fast",
        system: summarizeSystem(),
        messages: [
          {
            role: "user",
            text: `PREVIOUS SUMMARY:\n${summary || "(none)"}\n\nNEW TURNS:\n${toSummarize.map((t) => `${t.role}: ${t.text}`).join("\n")}`,
          },
        ],
        schema: SUMMARY_SCHEMA,
        maxOutputTokens: 400,
      });
      await recordUsage(deps, uid, day, s);
      const text = str(asRecord(s.json).summary, LIMITS.summary).trim();
      if (text) summary = newSummary = text;
    }

    const tier = routeChat(message, { premium, historyTurns: history.length });
    const userTurn = `${chatContextBlock({ context, memories, summary, memoryEnabled })}\n\nUSER MESSAGE:\n${message}`;
    const messages = normalizeTurns([...history, { role: "user", text: userTurn }], LIMITS.turns + 1);
    const result = await deps.provider.generateJson({
      tier,
      system: chatSystem(),
      messages,
      schema: CHAT_SCHEMA,
      maxOutputTokens: outputBudget("chat", tier),
    });
    await recordUsage(deps, uid, day, result);
    const valid = validateChat(result.json, memoryEnabled);
    if (!valid) throw new ProviderError("chat output failed validation", "bad_output");
    if (valid.rejected > 0) logger.info("Dropped invalid AI actions", { count: valid.rejected });
    return {
      reply: valid.reply,
      actions: valid.actions,
      memorySuggestions: valid.memorySuggestions,
      ...(newSummary ? { summary: newSummary } : {}),
      credits: reserved.view,
      tier,
      promptVersion: PROMPT_VERSION,
    };
  } catch (e) {
    await deps.usage.refund(uid, day, creditCost("chat"));
    throw e instanceof HttpsError ? e : providerError(e);
  }
}

export async function handleTask(uid: string, data: unknown, deps: Deps) {
  const d = asRecord(data);
  const task = typeof d.task === "string" ? d.task : "";
  const schema = TASK_SCHEMAS[task];
  const system = taskSystem(task);
  if (!schema || !system) throw new HttpsError("invalid-argument", "Unknown task.");
  const input = asRecord(d.input);
  if (stableStringify(input).length > LIMITS.inputBytes) throw new HttpsError("invalid-argument", "Input too large.");

  const now = deps.now();
  const day = dayKey(now, d.timeZone);
  const premium = await deps.usage.isPremium(uid, now);
  const tier = routeTask(task, { premium });
  const model = deps.provider.modelFor(tier);
  const cacheKey = AiCache.key({ task, model, v: PROMPT_VERSION, input });

  const cached = await deps.cache.get(cacheKey, now.getTime());
  if (cached) return { result: cached, credits: await deps.usage.view(uid, day, deps.config, premium), cached: true };

  const cost = creditCost(task);
  const reserved = await deps.usage.reserve(uid, day, deps.config, premium, cost, now.getTime());
  if (!reserved.ok) throw quotaError(reserved.reason, reserved.view);
  try {
    const r = await deps.provider.generateJson({
      tier,
      system,
      messages: [{ role: "user", text: taskUserBlock(input, input.locale) }],
      schema,
      maxOutputTokens: outputBudget(task, tier),
    });
    await recordUsage(deps, uid, day, r);
    const result = validateTask(task, r.json);
    if (!result) throw new ProviderError("task output failed validation", "bad_output");
    await deps.cache.put(cacheKey, result, now.getTime());
    return { result, credits: reserved.view, cached: false };
  } catch (e) {
    await deps.usage.refund(uid, day, cost);
    throw e instanceof HttpsError ? e : providerError(e);
  }
}

export async function handleCredits(uid: string, data: unknown, deps: Pick<Deps, "usage" | "config" | "now">) {
  const now = deps.now();
  const day = dayKey(now, asRecord(data).timeZone);
  const premium = await deps.usage.isPremium(uid, now);
  return { credits: await deps.usage.view(uid, day, deps.config, premium) };
}

export async function handleReward(uid: string, data: unknown, deps: Pick<Deps, "usage" | "config" | "now">) {
  const now = deps.now();
  const d = asRecord(data);
  const day = dayKey(now, d.timeZone);
  const premium = await deps.usage.isPremium(uid, now);
  const { granted, view } = await deps.usage.grantReward(uid, day, deps.config, premium);
  if (!granted) throw new HttpsError("resource-exhausted", "Daily reward limit reached.", { reason: "reward_cap", credits: view });
  logger.info("rewarded_ad_granted", { placement: str(d.placement, 40) });
  return { credits: view };
}
