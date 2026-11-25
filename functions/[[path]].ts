import { Hono } from "hono";
import { applyChannelQuery } from "../src/shared/channel-query.ts";
import { hotHours, hotRowsSql, reportFromRows, type HotRow } from "../src/server/hot-report.ts";

type Bindings = { DB: D1Database };
const app = new Hono<{ Bindings: Bindings }>();

function bounded(value: string | undefined, fallback: number, max: number) {
  return /^\d+$/.test(value ?? "") ? Math.min(Number(value), max) : fallback;
}

function item(row: Record<string, unknown>) {
  return { ...row, tags: JSON.parse(String(row.tags)), codes: JSON.parse(String(row.codes)),
    starred: Boolean(row.starred), read: Boolean(row.read_at), matched: [],
    ai: row.ai ? JSON.parse(String(row.ai)) : null };
}

app.get("/health", async (c) => c.json({
  ok: await c.env.DB.prepare("SELECT COUNT(*) FROM sources").first() !== null,
  runtimeMode: "cloudflare-pages",
}));
app.get("/api/auth/check", (c) => c.json({ ok: true, protected: true, isAdmin: false, adminLocked: true, adminHostAllowed: false }));
app.get("/api/site/bootstrap", (c) => c.json({
  siteMode: "public", loginEnabled: false, registrationMode: "closed", suspendUserSessionsOnClose: false,
  minTrustLevel: 0, oauthConfigured: false, githubConfigured: false, devMockEnabled: false,
  adminConfigured: false, adminLocked: true, isAdmin: false, user: null,
  onboarding: { enabled: true, title: "Cloudflare 部署预览版", content: "RSS 条目未经过 AI 验真。请切换到「全部白嫖」或「好价」浏览采集结果。", showGuideCards: false, version: 1 },
  features: { rss: false, userPush: false },
}));
app.get("/api/items", async (c) => {
  const query = applyChannelQuery(c.req.query());
  const where = ["status='active'"];
  const params: (string | number)[] = [];
  for (const [param, column] of [["kind", "kind"], ["category", "category"], ["source", "source_id"]] as const) {
    const value = query[param];
    if (value && value !== "all") {
      const list = value.split(",").slice(0, 12);
      where.push(column + " IN (" + list.map(() => "?").join(",") + ")");
      params.push(...list);
    }
  }
  if (query.aiOnly === "1") where.push("ai_keep=1");
  if (query.freeOnly === "1") where.push("is_free=1");
  if (query.hasCodes === "1") where.push("json_array_length(codes)>0");
  if (query.unexpired === "1") where.push("(expires_at IS NULL OR expires_at > datetime('now'))");
  if (query.obtain) {
    const obtain = query.obtain.split(",").slice(0, 10);
    where.push("obtain IN (" + obtain.map(() => "?").join(",") + ")");
    params.push(...obtain);
  }
  const q = (query.search ?? query.q)?.trim().slice(0, 100);
  if (q) {
    where.push("instr(lower(title || ' ' || coalesce(summary,'') || ' ' || coalesce(title_zh,'') || ' ' || coalesce(summary_zh,'')),lower(?)) > 0");
    params.push(q);
  }
  const ids = query.ids?.split(",").filter((id) => /^\d+$/.test(id)).slice(0, 30);
  if (ids?.length) {
    where.push("id IN (" + ids.map(() => "?").join(",") + ")");
    params.push(...ids);
  }
  if (query.ids !== undefined && !ids?.length) return c.json({ total: 0, items: [] });
  const since = c.req.query("since");
  if (since) {
    where.push("COALESCE(published_at,first_seen_at) >= ?");
    params.push(since);
  }
  const filter = where.join(" AND ");
  const db = c.env.DB;
  const [count, page] = await db.batch([
    db.prepare("SELECT COUNT(*) AS total FROM items WHERE " + filter).bind(...params),
    db.prepare("SELECT * FROM items WHERE " + filter + " ORDER BY COALESCE(published_at,first_seen_at) DESC, id DESC LIMIT ? OFFSET ?")
      .bind(...params, Math.max(1, bounded(c.req.query("limit"), 50, 100)), bounded(c.req.query("offset"), 0, 10000)),
  ]);
  return c.json({ total: count?.results[0]?.total ?? 0, items: (page?.results ?? []).map(item) });
});
app.get("/api/items/:id", async (c) => {
  const row = await c.env.DB.prepare("SELECT * FROM items WHERE id=? AND status='active'").bind(c.req.param("id")).first();
  return row ? c.json(item(row)) : c.json({ error: "未找到" }, 404);
});
app.get("/api/sources", async (c) => {
  const { results } = await c.env.DB.prepare(`SELECT s.id,s.name,s.kind,s.enabled,s.interval_sec,s.last_run_at,s.last_status,s.last_error,
      (SELECT COUNT(*) FROM items WHERE source_id=s.id) AS items,
      (SELECT MAX(first_seen_at) FROM items WHERE source_id=s.id) AS latest_item_at FROM sources s ORDER BY s.id`).all();
  return c.json({ sources: results.map((row) => ({ ...row, config: {}, enabled: Boolean(row.enabled), builtIn: true })) });
});
app.get("/api/stats", async (c) => {
  const db = c.env.DB;
  const tables = await db.batch([
    db.prepare("SELECT kind,count(*) AS n FROM items WHERE status='active' GROUP BY kind"),
    db.prepare("SELECT category,count(*) AS n FROM items WHERE status='active' GROUP BY category"),
    db.prepare("SELECT source_id,count(*) AS n FROM items WHERE status='active' GROUP BY source_id"),
  ]);
  const byKind = tables[0]?.results ?? [];
  const total = byKind.reduce((sum, row) => sum + Number(row.n), 0);
  return c.json({ byKind, byCategory: tables[1]?.results ?? [], bySource: tables[2]?.results ?? [],
    totals: { total, active: total, unread: total, cleanFree: 0,
      starred: 0, expired: 0, withCodes: 0, last24h: 0, blockRules: 0, aiKept: 0, aiRejected: 0 },
    features: { ai: false, push: false, pushChannel: "none" } });
});
app.get("/api/hot", async (c) => {
  const hours = hotHours(Number(c.req.query("hours") || 24));
  const now = new Date();
  const since = new Date(now.getTime() - 2 * hours * 3_600_000).toISOString();
  const { results } = await c.env.DB.prepare(hotRowsSql + " LIMIT 200").bind(since).all<HotRow>();
  return c.json(reportFromRows(results, hours, now, c.req.query("scope")));
});
app.get("/api/digests", async (c) => {
  const { results } = await c.env.DB.prepare("SELECT date,json_array_length(item_ids) AS count,created_at,pushed_at,kind FROM digests ORDER BY date DESC LIMIT 30").all();
  return c.json({ digests: results });
});
app.get("/api/digests/:date", async (c) => {
  const db = c.env.DB;
  const row = await db.prepare("SELECT payload, item_ids, created_at, pushed_at FROM digests WHERE date=?")
    .bind(c.req.param("date")).first<{ payload: string; item_ids: string; created_at: string; pushed_at: string | null }>();
  if (!row) return c.json({ error: "未找到" }, 404);
  const { results } = await db.prepare("SELECT i.* FROM json_each(?) j JOIN items i ON i.id=j.value ORDER BY j.key")
    .bind(row.item_ids).all();
  return c.json({ ...JSON.parse(row.payload), created_at: row.created_at, pushed_at: row.pushed_at, items: results.map(item) });
});
app.notFound((c) => c.json({ error: "Cloudflare 预览版尚未移植此接口" }, 501));

export const onRequest: PagesFunction<Bindings> = (context) => app.fetch(context.request, context.env);
