import Anthropic from "@anthropic-ai/sdk";

import { AIProvider, GenerateJsonRequest, GenerateJsonResult, ModelTier, ProviderError } from "../types";

/** Models whose safety classifiers can decline; they get server-side fallbacks. */
const FALLBACK_MODELS = new Set(["claude-opus-5-5", "claude-opus-5", "claude-fable-5-1", "claude-sonnet-5-5"]);

/**
 * Anthropic Claude via the official SDK. Structured output is requested with
 * `output_config.format` (JSON schema), so replies are always parseable JSON.
 */
export class AnthropicProvider implements AIProvider {
  readonly name = "anthropic";
  private readonly client: Anthropic;

  constructor(
    apiKey: string,
    private readonly models: Record<ModelTier, string> = {
      fast: process.env.ANTHROPIC_MODEL_FAST || "claude-haiku-4-5",
      smart: process.env.ANTHROPIC_MODEL_SMART || "claude-opus-5-5",
    },
    client?: Anthropic,
  ) {
    this.client = client ?? new Anthropic({ apiKey, maxRetries: 2, timeout: 40_000 });
  }

  modelFor(tier: ModelTier): string {
    return this.models[tier];
  }

  async generateJson(req: GenerateJsonRequest): Promise<GenerateJsonResult> {
    const model = this.modelFor(req.tier);
    const withFallback = FALLBACK_MODELS.has(model);
    let response;
    try {
      response = await this.client.beta.messages.create({
        model,
        max_tokens: req.maxOutputTokens,
        system: req.system,
        // Stable system prompt first → prefix caching across users.
        cache_control: { type: "ephemeral" },
        messages: req.messages.map((m) => ({ role: m.role, content: m.text })),
        output_config: {
          format: { type: "json_schema", schema: req.schema },
          // Haiku 4.5 does not take `effort`; the smart tier runs at medium.
          ...(req.tier === "smart" ? { effort: "medium" as const } : {}),
        },
        ...(withFallback ? { betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" as const } : {}),
      });
    } catch (e) {
      if (e instanceof Anthropic.RateLimitError) throw new ProviderError("rate limited", "rate_limited");
      if (e instanceof Anthropic.BadRequestError) throw new ProviderError(`bad request: ${e.message}`, "config");
      if (e instanceof Anthropic.AuthenticationError) throw new ProviderError("auth", "config");
      if (e instanceof Anthropic.APIError) throw new ProviderError(`api ${e.status}`, "unavailable");
      throw new ProviderError(String(e), "unavailable");
    }
    if (response.stop_reason === "refusal") throw new ProviderError("refused", "refused");
    if (response.stop_reason === "max_tokens") throw new ProviderError("truncated", "bad_output");
    const text = response.content
      .filter((b): b is Extract<typeof b, { type: "text" }> => b.type === "text")
      .map((b) => b.text)
      .join("");
    let json: unknown;
    try {
      json = JSON.parse(text);
    } catch {
      throw new ProviderError("non-JSON output", "bad_output");
    }
    return {
      json,
      usage: {
        inputTokens: response.usage.input_tokens,
        outputTokens: response.usage.output_tokens,
        cacheReadTokens: response.usage.cache_read_input_tokens ?? 0,
        cacheWriteTokens: response.usage.cache_creation_input_tokens ?? 0,
      },
      model: response.model,
      provider: this.name,
    };
  }
}
