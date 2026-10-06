import { AIProvider, GenerateJsonRequest, GenerateJsonResult, ModelTier, ProviderError } from "../types";

/**
 * OpenAI Chat Completions with JSON-schema structured output (raw HTTPS).
 * Models are configured via OPENAI_MODEL_FAST / OPENAI_MODEL_SMART.
 */
export class OpenAIProvider implements AIProvider {
  readonly name = "openai";

  constructor(
    private readonly apiKey: string,
    private readonly models: Record<ModelTier, string | undefined> = {
      fast: process.env.OPENAI_MODEL_FAST,
      smart: process.env.OPENAI_MODEL_SMART,
    },
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  modelFor(tier: ModelTier): string {
    const m = this.models[tier];
    if (!m) throw new ProviderError(`OPENAI_MODEL_${tier.toUpperCase()} not set`, "config");
    return m;
  }

  async generateJson(req: GenerateJsonRequest): Promise<GenerateJsonResult> {
    const model = this.modelFor(req.tier);
    const res = await this.fetchImpl("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${this.apiKey}` },
      body: JSON.stringify({
        model,
        max_completion_tokens: req.maxOutputTokens,
        messages: [{ role: "system", content: req.system }, ...req.messages.map((m) => ({ role: m.role, content: m.text }))],
        response_format: { type: "json_schema", json_schema: { name: "lifeos_response", strict: true, schema: req.schema } },
      }),
      signal: AbortSignal.timeout(40_000),
    });
    if (res.status === 429) throw new ProviderError("rate limited", "rate_limited");
    if (!res.ok) throw new ProviderError(`openai ${res.status}`, res.status >= 500 ? "unavailable" : "config");
    const body = (await res.json()) as {
      model?: string;
      choices?: { message?: { content?: string | null; refusal?: string | null }; finish_reason?: string }[];
      usage?: { prompt_tokens?: number; completion_tokens?: number; prompt_tokens_details?: { cached_tokens?: number } };
    };
    const choice = body.choices?.[0];
    if (choice?.message?.refusal) throw new ProviderError("refused", "refused");
    if (choice?.finish_reason === "length") throw new ProviderError("truncated", "bad_output");
    let json: unknown;
    try {
      json = JSON.parse(choice?.message?.content ?? "");
    } catch {
      throw new ProviderError("non-JSON output", "bad_output");
    }
    const cached = body.usage?.prompt_tokens_details?.cached_tokens ?? 0;
    return {
      json,
      usage: {
        inputTokens: (body.usage?.prompt_tokens ?? 0) - cached,
        outputTokens: body.usage?.completion_tokens ?? 0,
        cacheReadTokens: cached,
      },
      model: body.model ?? model,
      provider: this.name,
    };
  }
}
