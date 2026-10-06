import { Usage } from "./types";

/** USD per 1M tokens. */
export interface Price {
  input: number;
  output: number;
  cacheRead?: number;
  cacheWrite?: number;
}

/**
 * Anthropic first-party list prices (Claude API). Other providers' prices
 * are supplied via the AI_PRICING_JSON env var, e.g.
 * {"my-model": {"input": 0.5, "output": 1.5}} — verify against the vendor's
 * current price list.
 */
const BUILT_IN: Record<string, Price> = {
  "claude-opus-5-5": { input: 4, output: 20, cacheRead: 0.2, cacheWrite: 5 },
  "claude-haiku-4-5": { input: 1, output: 5, cacheRead: 0.1, cacheWrite: 1.25 },
  "claude-sonnet-5-5": { input: 2, output: 10, cacheRead: 0.2, cacheWrite: 2.5 },
};

function table(): Record<string, Price> {
  try {
    return { ...BUILT_IN, ...(JSON.parse(process.env.AI_PRICING_JSON || "{}") as Record<string, Price>) };
  } catch {
    return BUILT_IN;
  }
}

/** Estimated request cost in USD; unknown models fall back to the most expensive known price. */
export function estimateCostUsd(model: string, usage: Usage): number {
  const prices = table();
  const key = Object.keys(prices).find((k) => model === k || model.startsWith(`${k}-`));
  const p = key ? prices[key] : { input: 10, output: 50 };
  const cost =
    usage.inputTokens * p.input +
    usage.outputTokens * p.output +
    (usage.cacheReadTokens ?? 0) * (p.cacheRead ?? p.input) +
    (usage.cacheWriteTokens ?? 0) * (p.cacheWrite ?? p.input);
  return cost / 1_000_000;
}
