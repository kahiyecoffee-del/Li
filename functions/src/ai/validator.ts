import { asRecord, str } from "../lib/util";
import { EXPENSE_CATEGORIES, INTENTS, MEMORY_CATEGORIES, SHOPPING_CATEGORIES } from "./schemas";

/**
 * AIResponseValidator (server side). Model output is untrusted: only
 * allow-listed intents with well-typed, bounded fields pass. The app
 * validates again before showing anything, and every action still needs the
 * user's confirmation. Nothing here is ever executed as code.
 */
export interface ValidAction {
  intent: string;
  requires_confirmation: true;
  data: Record<string, unknown>;
}

const DATE = /^\d{4}-\d{2}-\d{2}/;
const TIME = /^([01]?\d|2[0-3]):[0-5]\d$/;
const PRIORITIES = ["low", "medium", "high"];
const TASK_CATEGORIES = ["work", "personal", "health", "errands", "learning", "social", "other"];
const HABIT_TYPES = ["water", "reading", "exercise", "meditation", "sleep", "custom"];
const MAX_AMOUNT = 1_000_000_000;

function text(v: unknown, max: number): string | undefined {
  const s = str(v, max + 1).trim();
  return s && s.length <= max ? s : undefined;
}
function int(v: unknown, min: number, max: number): number | undefined {
  return typeof v === "number" && Number.isInteger(v) && v >= min && v <= max ? v : undefined;
}
function amount(v: unknown): number | undefined {
  return typeof v === "number" && Number.isFinite(v) && v > 0 && v <= MAX_AMOUNT ? Math.round(v * 100) / 100 : undefined;
}
function oneOf(v: unknown, values: readonly string[]): string | undefined {
  return typeof v === "string" && values.includes(v) ? v : undefined;
}
function date(v: unknown): string | undefined {
  return typeof v === "string" && DATE.test(v) && !Number.isNaN(Date.parse(v.slice(0, 10))) ? v.slice(0, 10) : undefined;
}
function compact(o: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined));
}

export function validateAction(raw: unknown): ValidAction | null {
  const a = asRecord(raw);
  const intent = oneOf(a.intent, INTENTS);
  if (!intent) return null;
  const d = asRecord(a.data);
  let data: Record<string, unknown> | null;
  switch (intent) {
    case "create_task": {
      const title = text(d.title, 120);
      data = title
        ? compact({
            title,
            date: date(d.date),
            time: typeof d.time === "string" && TIME.test(d.time) ? d.time : undefined,
            duration_minutes: int(d.duration_minutes, 5, 720),
            priority: oneOf(d.priority, PRIORITIES),
            category: oneOf(d.category, TASK_CATEGORIES),
          })
        : null;
      break;
    }
    case "optimize_plan":
      data = {};
      break;
    case "create_budget": {
      const amt = amount(d.amount);
      data = amt ? compact({ amount: amt, period: oneOf(d.period, ["week", "month"]) ?? "month", category: oneOf(d.category, EXPENSE_CATEGORIES) }) : null;
      break;
    }
    case "add_expense": {
      const amt = amount(d.amount);
      data = amt
        ? compact({ amount: amt, category: oneOf(d.category, EXPENSE_CATEGORIES) ?? "other", description: text(d.description, 120), date: date(d.date) })
        : null;
      break;
    }
    case "set_savings_goal": {
      const amt = amount(d.amount);
      data = amt ? { amount: amt } : null;
      break;
    }
    case "generate_meal_plan":
      data = compact({ date: date(d.date), use_pantry: typeof d.use_pantry === "boolean" ? d.use_pantry : undefined });
      break;
    case "add_shopping_items": {
      const items = Array.isArray(d.items)
        ? [...new Set(d.items.map((i) => text(i, 60)).filter((i): i is string => !!i))].slice(0, 40)
        : [];
      data = items.length ? { items } : null;
      break;
    }
    case "create_habit": {
      const name = text(d.name, 60);
      data = name ? compact({ name, type: oneOf(d.type, HABIT_TYPES) ?? "custom", target_per_day: int(d.target_per_day, 1, 100) }) : null;
      break;
    }
    case "log_mood": {
      const mood = int(d.mood, 1, 5);
      data = mood ? compact({ mood, note: text(d.note, 500) }) : null;
      break;
    }
    case "save_memory": {
      const category = oneOf(d.category, MEMORY_CATEGORIES);
      const content = text(d.content, 200);
      data = category && content ? { category, content } : null;
      break;
    }
    default:
      data = null;
  }
  return data ? { intent, requires_confirmation: true, data } : null;
}

export interface ValidChat {
  reply: string;
  actions: ValidAction[];
  memorySuggestions: { category: string; content: string }[];
  rejected: number;
}

export function validateChat(raw: unknown, memoryEnabled: boolean): ValidChat | null {
  const r = asRecord(raw);
  const reply = str(r.reply, 4000).trim();
  const rawActions = Array.isArray(r.actions) ? r.actions.slice(0, 5) : [];
  const actions = rawActions.map(validateAction).filter((a): a is ValidAction => a !== null);
  if (!reply && actions.length === 0) return null;
  const memorySuggestions = memoryEnabled && Array.isArray(r.memorySuggestions)
    ? r.memorySuggestions
        .map((m) => {
          const o = asRecord(m);
          const category = oneOf(o.category, MEMORY_CATEGORIES);
          const content = text(o.content, 200);
          return category && content ? { category, content } : null;
        })
        .filter((m): m is { category: string; content: string } => m !== null)
        .slice(0, 3)
    : [];
  return { reply, actions, memorySuggestions, rejected: rawActions.length - actions.length };
}

/** Validates task results; returns the client-facing `result` or null. */
export function validateTask(task: string, raw: unknown): Record<string, unknown> | null {
  const r = asRecord(raw);
  switch (task) {
    case "parse_expense":
      return { amount: amount(r.amount) ?? null, category: oneOf(r.category, EXPENSE_CATEGORIES) ?? "other", description: text(r.description, 120) ?? "" };
    case "categorize_shopping": {
      const out: Record<string, string> = {};
      for (const c of Array.isArray(r.categories) ? r.categories.slice(0, 60) : []) {
        const o = asRecord(c);
        const name = text(o.name, 60);
        const cat = oneOf(o.category, SHOPPING_CATEGORIES);
        if (name && cat) out[name] = cat;
      }
      return { categories: out };
    }
    case "meal_plan": {
      const meals = (Array.isArray(r.meals) ? r.meals.slice(0, 6) : [])
        .map((m) => {
          const o = asRecord(m);
          const name = text(o.name, 80);
          const ingredients = Array.isArray(o.ingredients) ? o.ingredients.map((i) => text(i, 60)).filter(Boolean).slice(0, 20) : [];
          if (!name || ingredients.length === 0) return null;
          return {
            name,
            mealType: oneOf(o.mealType, ["breakfast", "lunch", "dinner", "snack"]) ?? "lunch",
            ingredients,
            steps: Array.isArray(o.steps) ? o.steps.map((s) => text(s, 300)).filter(Boolean).slice(0, 12) : [],
            calories: int(o.calories, 0, 3000) ?? 0,
            proteinG: int(o.proteinG, 0, 300) ?? 0,
            carbsG: int(o.carbsG, 0, 500) ?? 0,
            fatG: int(o.fatG, 0, 300) ?? 0,
            prepMinutes: int(o.prepMinutes, 0, 600) ?? 0,
            difficulty: oneOf(o.difficulty, ["easy", "medium", "hard"]) ?? "easy",
            estimatedCost: amount(o.estimatedCost) ?? null,
          };
        })
        .filter((m) => m !== null);
      return meals.length ? { meals } : null;
    }
    case "weekly_summary":
    case "monthly_summary":
    case "news_why": {
      const t = text(r.text, 1500);
      return t ? { text: t } : null;
    }
    default:
      return null;
  }
}
