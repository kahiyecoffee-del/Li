/** Model tier chosen by the router: cheap/fast vs capable/expensive. */
export type ModelTier = "fast" | "smart";

export interface ChatTurn {
  role: "user" | "assistant";
  text: string;
}

export interface GenerateJsonRequest {
  tier: ModelTier;
  system: string;
  messages: ChatTurn[];
  /** JSON schema the model must follow. */
  schema: Record<string, unknown>;
  maxOutputTokens: number;
}

export interface Usage {
  /** Uncached input tokens. */
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens?: number;
  cacheWriteTokens?: number;
}

export interface GenerateJsonResult {
  /** Parsed JSON object (not yet semantically validated). */
  json: unknown;
  usage: Usage;
  model: string;
  provider: string;
}

/**
 * Provider abstraction ("AIProvider"). Anthropic, OpenAI and Gemini
 * implement it; swapping providers is a config change (AI_PROVIDER).
 */
export interface AIProvider {
  readonly name: string;
  modelFor(tier: ModelTier): string;
  generateJson(req: GenerateJsonRequest): Promise<GenerateJsonResult>;
}

export class ProviderError extends Error {
  constructor(
    message: string,
    readonly kind: "refused" | "rate_limited" | "unavailable" | "bad_output" | "config",
  ) {
    super(message);
  }
}
