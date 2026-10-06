/**
 * JSON schemas for structured AI output. Written to be compatible with the
 * strictest provider mode (OpenAI strict JSON schema): every property is
 * required and optional values are nullable; no additional properties.
 */
type Schema = Record<string, unknown>;

const nullable = (type: string): Schema => ({ type: [type, "null"] });
const obj = (properties: Record<string, Schema>): Schema => ({
  type: "object",
  properties,
  required: Object.keys(properties),
  additionalProperties: false,
});

export const INTENTS = [
  "create_task",
  "optimize_plan",
  "create_budget",
  "add_expense",
  "set_savings_goal",
  "generate_meal_plan",
  "add_shopping_items",
  "create_habit",
  "log_mood",
  "save_memory",
] as const;
export type Intent = (typeof INTENTS)[number];

export const MEMORY_CATEGORIES = ["preferences", "goals", "habits", "food", "budget", "schedule"] as const;
export const EXPENSE_CATEGORIES = [
  "housing",
  "food",
  "transport",
  "shopping",
  "bills",
  "entertainment",
  "health",
  "subscriptions",
  "other",
] as const;
export const SHOPPING_CATEGORIES = [
  "produce",
  "meat",
  "dairy",
  "bakery",
  "pantry",
  "frozen",
  "drinks",
  "household",
  "personalCare",
  "other",
] as const;

const actionData = obj({
  title: nullable("string"),
  date: nullable("string"),
  time: nullable("string"),
  duration_minutes: nullable("integer"),
  priority: nullable("string"),
  category: nullable("string"),
  period: nullable("string"),
  amount: nullable("number"),
  description: nullable("string"),
  items: { type: ["array", "null"], items: { type: "string" } },
  name: nullable("string"),
  type: nullable("string"),
  target_per_day: nullable("integer"),
  mood: nullable("integer"),
  note: nullable("string"),
  content: nullable("string"),
  use_pantry: nullable("boolean"),
});

export const CHAT_SCHEMA: Schema = obj({
  reply: { type: "string" },
  actions: {
    type: "array",
    items: obj({
      intent: { type: "string", enum: [...INTENTS] },
      requires_confirmation: { type: "boolean" },
      data: actionData,
    }),
  },
  memorySuggestions: {
    type: "array",
    items: obj({ category: { type: "string", enum: [...MEMORY_CATEGORIES] }, content: { type: "string" } }),
  },
});

export const SUMMARY_SCHEMA: Schema = obj({ summary: { type: "string" } });

export const TEXT_SCHEMA: Schema = obj({ text: { type: "string" } });

export const PARSE_EXPENSE_SCHEMA: Schema = obj({
  amount: nullable("number"),
  category: { type: "string", enum: [...EXPENSE_CATEGORIES] },
  description: { type: "string" },
});

export const CATEGORIZE_SCHEMA: Schema = obj({
  categories: {
    type: "array",
    items: obj({ name: { type: "string" }, category: { type: "string", enum: [...SHOPPING_CATEGORIES] } }),
  },
});

export const MEAL_PLAN_SCHEMA: Schema = obj({
  meals: {
    type: "array",
    items: obj({
      name: { type: "string" },
      mealType: { type: "string", enum: ["breakfast", "lunch", "dinner", "snack"] },
      ingredients: { type: "array", items: { type: "string" } },
      steps: { type: "array", items: { type: "string" } },
      calories: { type: "integer" },
      proteinG: { type: "integer" },
      carbsG: { type: "integer" },
      fatG: { type: "integer" },
      prepMinutes: { type: "integer" },
      difficulty: { type: "string", enum: ["easy", "medium", "hard"] },
      estimatedCost: nullable("number"),
    }),
  },
});
