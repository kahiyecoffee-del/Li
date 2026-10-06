import { AIProvider, GenerateJsonRequest, GenerateJsonResult, ModelTier, ProviderError } from "../types";

/**
 * Google Gemini generateContent with a JSON response schema (raw HTTPS).
 * Models are configured via GEMINI_MODEL_FAST / GEMINI_MODEL_SMART.
 */
export class GeminiProvider implements AIProvider {
  readonly name = "gemini";

  constructor(
    private readonly apiKey: string,
    private readonly models: Record<ModelTier, string | undefined> = {
      fast: process.env.GEMINI_MODEL_FAST,
      smart: process.env.GEMINI_MODEL_SMART,
    },
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  modelFor(tier: ModelTier): string {
    const m = this.models[tier];
    if (!m) throw new ProviderError(`GEMINI_MODEL_${tier.toUpperCase()} not set`, "config");
    return m;
  }

  async generateJson(req: GenerateJsonRequest): Promise<GenerateJsonResult> {
    const model = this.modelFor(req.tier);
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
    const res = await this.fetchImpl(url, {
      method: "POST",
      headers: { "content-type": "application/json", "x-goog-api-key": this.apiKey },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: req.system }] },
        contents: req.messages.map((m) => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.text }] })),
        generationConfig: {
          maxOutputTokens: req.maxOutputTokens,
          responseMimeType: "application/json",
          responseJsonSchema: req.schema,
        },
      }),
      signal: AbortSignal.timeout(40_000),
    });
    if (res.status === 429) throw new ProviderError("rate limited", "rate_limited");
    if (!res.ok) throw new ProviderError(`gemini ${res.status}`, res.status >= 500 ? "unavailable" : "config");
    const body = (await res.json()) as {
      candidates?: { content?: { parts?: { text?: string }[] }; finishReason?: string }[];
      promptFeedback?: { blockReason?: string };
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; cachedContentTokenCount?: number };
    };
    if (body.promptFeedback?.blockReason) throw new ProviderError("refused", "refused");
    const cand = body.candidates?.[0];
    if (cand?.finishReason === "SAFETY") throw new ProviderError("refused", "refused");
    if (cand?.finishReason === "MAX_TOKENS") throw new ProviderError("truncated", "bad_output");
    let json: unknown;
    try {
      json = JSON.parse(cand?.content?.parts?.map((p) => p.text ?? "").join("") ?? "");
    } catch {
      throw new ProviderError("non-JSON output", "bad_output");
    }
    const cached = body.usageMetadata?.cachedContentTokenCount ?? 0;
    return {
      json,
      usage: {
        inputTokens: (body.usageMetadata?.promptTokenCount ?? 0) - cached,
        outputTokens: body.usageMetadata?.candidatesTokenCount ?? 0,
        cacheReadTokens: cached,
      },
      model,
      provider: this.name,
    };
  }
}
