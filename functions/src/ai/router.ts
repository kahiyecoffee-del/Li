import { ModelTier } from "./types";

/**
 * Model routing: the cheap/fast tier handles most traffic; the smart tier is
 * used only where quality matters enough to justify the cost.
 */
const COMPLEX_HINTS = [
  // en
  "plan", "budget", "save", "saving", "why", "optimi", "analy", "compare", "week", "month", "strategy", "goal",
  // tr
  "planla", "bütçe", "birik", "neden", "analiz", "hafta", "ay ", "hedef", "karşılaştır",
];

export function routeChat(message: string, opts: { premium: boolean; historyTurns: number }): ModelTier {
  if (opts.premium) return "smart";
  const m = message.toLowerCase();
  if (m.length > 280) return "smart";
  if (COMPLEX_HINTS.some((h) => m.includes(h))) return "smart";
  return "fast";
}

export function routeTask(task: string, opts: { premium: boolean }): ModelTier {
  if (task === "monthly_summary" && opts.premium) return "smart";
  if (task === "meal_plan" && opts.premium) return "smart";
  return "fast";
}

/** Credits charged per request type (0 = free, but separately capped). */
export function creditCost(kind: string): number {
  return kind === "parse_expense" || kind === "categorize_shopping" ? 0 : 1;
}

/** Max output tokens per request type (cost guardrail). Thinking-capable
 * smart models spend part of this on reasoning, hence the headroom. */
export function outputBudget(kind: string, tier: ModelTier): number {
  const base = kind === "chat" ? 1500 : kind === "meal_plan" ? 2500 : kind === "monthly_summary" ? 800 : 500;
  return tier === "smart" ? base * 4 : base;
}
