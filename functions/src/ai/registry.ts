import { defineSecret, defineString } from "firebase-functions/params";

import { AnthropicProvider } from "./providers/anthropic";
import { GeminiProvider } from "./providers/gemini";
import { OpenAIProvider } from "./providers/openai";
import { AIProvider, ProviderError } from "./types";

/** API keys live only in Secret Manager (`firebase functions:secrets:set …`). */
export const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");
export const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
export const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

/** Which provider serves requests: anthropic | openai | gemini. */
export const AI_PROVIDER = defineString("AI_PROVIDER", { default: "anthropic" });

let cached: { key: string; provider: AIProvider } | undefined;

export function getProvider(): AIProvider {
  const name = AI_PROVIDER.value();
  const key = name === "openai" ? OPENAI_API_KEY.value() : name === "gemini" ? GEMINI_API_KEY.value() : ANTHROPIC_API_KEY.value();
  if (!key) throw new ProviderError(`API key for ${name} is not configured`, "config");
  if (cached?.key === `${name}:${key}`) return cached.provider;
  const provider =
    name === "openai" ? new OpenAIProvider(key) : name === "gemini" ? new GeminiProvider(key) : new AnthropicProvider(key);
  cached = { key: `${name}:${key}`, provider };
  return provider;
}
