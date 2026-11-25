import { rssCollector } from "../src/server/collectors/rss.ts";
import { normalizeUrl } from "../src/server/enrich/normalize.ts";
import type { HttpClient } from "../src/server/http.ts";

const feeds = [
  { id: "rss-vpsgo", name: "VPSGO · 主机促销", url: "https://www.vpsgo.com/feed", kind: "deal", category: "vps" },
  { id: "rss-indiegamebundles", name: "IndieGameBundles", url: "https://www.indiegamebundles.com/category/free/feed/", kind: "freebie", category: "game" },
  { id: "rss-isthereanydeal", name: "IsThereAnyDeal", url: "https://isthereanydeal.com/feeds/US/giveaways.rss", kind: "freebie", category: "game" },
];

const text: HttpClient["text"] = async (url) => {
  const response = await fetch(url, { signal: AbortSignal.timeout(12_000) });
  if (!response.ok) throw new Error("HTTP " + response.status);
  const bytes = Buffer.from(await response.arrayBuffer());
  return {
    status: response.status, url: response.url, headers: response.headers,
    body: bytes.toString("utf8"), bytes, contentType: response.headers.get("content-type") ?? "",
  };
};

async function collect(db: D1Database, date: Date) {
  const source = feeds[Math.floor(date.getTime() / 3_600_000) % feeds.length]!;
  const now = date.toISOString();
  await db.prepare("INSERT OR IGNORE INTO sources (id,name,kind,created_at,interval_sec) VALUES (?,?,'rss',?,10800)")
    .bind(source.id, source.name, now).run();
  try {
    const result = await rssCollector.collect({
      sourceId: source.id, config: { feeds: [source] }, cursor: null, maxItems: 15,
      http: { text, raw: text, json: async () => { throw new Error("RSS requires text"); } },
      log: (message) => console.log(source.id, message),
    });
    const writes = result.items.flatMap((item) => {
      const key = normalizeUrl(item.url, source.url);
      if (!/^https?:\/\//.test(key)) return [];
      return [db.prepare(`INSERT OR IGNORE INTO items
        (source_id,external_id,url,url_key,title,summary,author,category,kind,image_url,tags,published_at,expires_at,first_seen_at,last_seen_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).bind(
        source.id, item.externalId, key, key, item.title, item.summary ?? null,
        item.author ?? null, source.category, source.kind, item.imageUrl ?? null,
        JSON.stringify(item.tags ?? []), item.publishedAt ?? null, item.expiresAt ?? null, now, now,
      )];
    });
    await db.batch([...writes, db.prepare("UPDATE sources SET last_run_at=?,last_status='ok',last_error=NULL WHERE id=?").bind(now, source.id)]);
  } catch (err) {
    await db.prepare("UPDATE sources SET last_run_at=?,last_status='failed',last_error=? WHERE id=?")
      .bind(now, err instanceof Error ? err.message : "采集失败", source.id).run();
    throw err;
  }
}

async function digest(db: D1Database, date: Date) {
  const day = date.toISOString().slice(0, 10);
  const { results } = await db.prepare(`SELECT id, title, url FROM items
    WHERE status='active' AND kind='freebie' AND first_seen_at >= ? AND first_seen_at < ?
    ORDER BY first_seen_at DESC LIMIT 10`)
    .bind(new Date(date.getTime() - 86_400_000).toISOString(), date.toISOString()).all<{ id: number; title: string; url: string }>();
  const content = results.map(({ title, url }) => title + " " + url).join("\n");
  await db.prepare("INSERT OR IGNORE INTO digests (date,item_ids,payload,created_at) VALUES (?,?,?,?)")
    .bind(day, JSON.stringify(results.map(({ id }) => id)), JSON.stringify({ date: day, count: results.length, text: content }), date.toISOString()).run();
}

export default {
  async scheduled(event: ScheduledController, env: { DB: D1Database }) {
    const date = new Date(event.scheduledTime);
    if (date.getUTCHours() === 0) await digest(env.DB, date);
    await collect(env.DB, date);
  },
};
