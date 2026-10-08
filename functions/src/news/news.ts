import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

export interface Article {
  id: string;
  title: string;
  description: string;
  source: string;
  url: string;
  topic: string;
  publishedAt?: string;
  imageUrl?: string;
}

export const TOPICS = [
  "nation",
  "world",
  "finance",
  "technology",
  "sports",
  "science",
  "health",
  "entertainment",
] as const;

/** News provider abstraction: switch with the NEWS_PROVIDER param. */
export interface NewsProvider {
  readonly name: string;
  headlines(topic: string, language: string): Promise<Article[]>;
}

function articleId(url: string): string {
  let h = 0;
  for (let i = 0; i < url.length; i++) h = (Math.imul(31, h) + url.charCodeAt(i)) | 0;
  return `a${(h >>> 0).toString(36)}`;
}

/** https://gnews.io — top headlines by category and language. */
export class GNewsProvider implements NewsProvider {
  readonly name = "gnews";
  constructor(private readonly apiKey: string, private readonly fetchImpl: typeof fetch = fetch) {}

  async headlines(topic: string, language: string): Promise<Article[]> {
    const category = topic === "finance" ? "business" : topic;
    const url = new URL("https://gnews.io/api/v4/top-headlines");
    url.search = new URLSearchParams({ category, lang: language, max: "6", apikey: this.apiKey }).toString();
    const res = await this.fetchImpl(url, { signal: AbortSignal.timeout(10_000) });
    if (!res.ok) throw new Error(`gnews ${res.status}`);
    const body = (await res.json()) as {
      articles?: { title?: string; description?: string; url?: string; image?: string; publishedAt?: string; source?: { name?: string } }[];
    };
    return (body.articles ?? [])
      .filter((a) => a.title && a.url?.startsWith("https://"))
      .map((a) => ({
        id: articleId(a.url!),
        title: a.title!.slice(0, 300),
        description: (a.description ?? "").slice(0, 500),
        source: (a.source?.name ?? "").slice(0, 80),
        url: a.url!,
        topic,
        publishedAt: a.publishedAt,
        imageUrl: a.image?.startsWith("https://") ? a.image : undefined,
      }));
  }
}

/** https://newsapi.org — top headlines by category (country-scoped). */
export class NewsApiProvider implements NewsProvider {
  readonly name = "newsapi";
  constructor(private readonly apiKey: string, private readonly fetchImpl: typeof fetch = fetch) {}

  async headlines(topic: string, language: string): Promise<Article[]> {
    const category = topic === "finance" ? "business" : topic === "world" || topic === "nation" ? "general" : topic;
    const country = { en: "us", tr: "tr", de: "de", fr: "fr", it: "it", pt: "br", es: "mx", ar: "sa", ja: "jp", ko: "kr", hi: "in" }[language] ?? "us";
    const url = new URL("https://newsapi.org/v2/top-headlines");
    url.search = new URLSearchParams({ category, country, pageSize: "6" }).toString();
    const res = await this.fetchImpl(url, { headers: { "X-Api-Key": this.apiKey }, signal: AbortSignal.timeout(10_000) });
    if (!res.ok) throw new Error(`newsapi ${res.status}`);
    const body = (await res.json()) as {
      articles?: { title?: string; description?: string; url?: string; urlToImage?: string; publishedAt?: string; source?: { name?: string } }[];
    };
    return (body.articles ?? [])
      .filter((a) => a.title && a.url?.startsWith("https://"))
      .map((a) => ({
        id: articleId(a.url!),
        title: a.title!.slice(0, 300),
        description: (a.description ?? "").slice(0, 500),
        source: (a.source?.name ?? "").slice(0, 80),
        url: a.url!,
        topic,
        publishedAt: a.publishedAt,
        imageUrl: a.urlToImage?.startsWith("https://") ? a.urlToImage : undefined,
      }));
  }
}

/** Shared cache: one provider call per (topic, language) per hour for all users. */
export async function getHeadlines(
  db: Firestore,
  provider: NewsProvider,
  topics: string[],
  language: string,
  now = Date.now(),
): Promise<Article[]> {
  const lang = /^[a-z]{2}$/.test(language) ? language : "en";
  const wanted = topics.filter((t): t is (typeof TOPICS)[number] => (TOPICS as readonly string[]).includes(t)).slice(0, 8);
  const lists = await Promise.all(
    (wanted.length ? wanted : ["world"]).map(async (topic) => {
      const ref = db.collection("news_cache").doc(`${provider.name}_${lang}_${topic}`);
      const snap = await ref.get();
      const d = snap.data();
      if (d && d.fetchedAt instanceof Timestamp && now - d.fetchedAt.toMillis() < 3600_000) return d.articles as Article[];
      try {
        const articles = await provider.headlines(topic, lang);
        await ref.set({ articles, fetchedAt: Timestamp.fromMillis(now), updatedAt: FieldValue.serverTimestamp() });
        return articles;
      } catch {
        return (d?.articles as Article[] | undefined) ?? [];
      }
    }),
  );
  // Interleave topics so the feed is varied.
  const out: Article[] = [];
  for (let i = 0; i < 6; i++) for (const l of lists) if (l[i]) out.push(l[i]);
  return out.slice(0, 24);
}
