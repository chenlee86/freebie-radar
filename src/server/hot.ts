import { all, get, dbRevision } from "./db.ts";
import { hotHours, hotRowsSql, reportFromRows, type HotReport, type HotRow } from "./hot-report.ts";
export * from "./hot-report.ts";

const cache = new Map<string, HotReport>();

export function buildHotReport(windowHours = 24, rawScope?: string): HotReport {
  const hours = hotHours(windowHours);
  const scope = rawScope ?? "all";
  const now = new Date();
  const bucket = `${hours}:${scope}:${Math.floor(now.getTime() / 600_000)}:${dbRevision()}`;
  const hit = cache.get(bucket);
  if (hit) return hit;
  if (cache.size > 8) cache.clear();

  const rows = all<HotRow>(hotRowsSql, new Date(now.getTime() - 2 * hours * 3_600_000).toISOString());
  const report = reportFromRows(rows, hours, now, rawScope);
  cache.set(bucket, report);
  return report;
}

/**
 * 来源质量榜：按源的 AI 留存率、平均质量分与推送命中率排，用来判断哪些源在浪费采集与 AI 额度。
 * 留存率 = AI 判为有效的条数 / 已审条数；未审核的条目单独计数，不掺进分母。
 */
export function sourceQuality(sinceDays = 7): {
  id: string;
  name: string;
  total: number;
  reviewed: number;
  kept: number;
  rejected: number;
  keepRate: number | null;
  avgQuality: number | null;
  pushed: number;
  lastRun: string | null;
  enabled: number;
  lastError: string | null;
}[] {
  const days = Math.min(Math.max(Math.round(sinceDays), 1), 90);
  const since = new Date(Date.now() - days * 86_400_000).toISOString();
  const rows = all<{
    id: string;
    name: string;
    enabled: number;
    last_run_at: string | null;
    last_error: string | null;
    total: number;
    reviewed: number;
    kept: number;
    rejected: number;
    avgQuality: number | null;
    pushed: number;
  }>(
    `SELECT s.id,
            s.name,
            s.enabled,
            s.last_run_at,
            s.last_error,
            COUNT(i.id) AS total,
            SUM(CASE WHEN i.ai_keep IS NOT NULL THEN 1 ELSE 0 END) AS reviewed,
            SUM(CASE WHEN i.ai_keep = 1 THEN 1 ELSE 0 END) AS kept,
            SUM(CASE WHEN i.ai_keep = 0 THEN 1 ELSE 0 END) AS rejected,
            AVG(CASE WHEN i.ai_quality IS NOT NULL THEN i.ai_quality END) AS avgQuality,
            SUM(CASE WHEN i.pushed_at IS NOT NULL THEN 1 ELSE 0 END) AS pushed
       FROM sources s
       LEFT JOIN items i
         ON i.source_id = s.id
        AND i.status = 'active'
        AND COALESCE(i.published_at, i.first_seen_at) >= ?
      GROUP BY s.id
      ORDER BY s.id`,
    since,
  );
  return rows.map((r) => ({
    id: r.id,
    name: r.name,
    total: Number(r.total ?? 0),
    reviewed: Number(r.reviewed ?? 0),
    kept: Number(r.kept ?? 0),
    rejected: Number(r.rejected ?? 0),
    keepRate: r.reviewed ? Number(r.kept) / Number(r.reviewed) : null,
    avgQuality: r.avgQuality === null ? null : Math.round(Number(r.avgQuality) * 10) / 10,
    pushed: Number(r.pushed ?? 0),
    lastRun: r.last_run_at,
    enabled: r.enabled,
    lastError: r.last_error,
  }));
}

