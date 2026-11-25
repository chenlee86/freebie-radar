# Cloudflare Pages + D1 部署（预览版）

本 Fork 由 chenlee86 基于 [ZiChuanLan/freebie-radar](https://github.com/ZiChuanLan/freebie-radar) 修改，沿用原项目 MIT 许可证。原 Docker Compose 路径仍适用于完整功能。

Cloudflare 版使用 Pages 托管原 Vite 前端，Pages Functions 从 D1 读取资源列表、详情、来源、今日热点及日报。热点单次最多统计 200 条候选。独立 Cron Worker 写入同一个 D1，不开放 HTTP 入口。

定时 Worker 通过 Workers AI 每小时最多翻译 4 条英文 RSS 标题和摘要，译文保存在 D1。简体中文界面优先显示译文，详情可展开原文，英文界面继续显示原文。额度不足或翻译失败时继续显示原文。

预览版每小时第 15 分钟轮询一个 RSS 源，默认包括 VPSGO、IndieGameBundles 和 IsThereAnyDeal，每源每三小时最多写入 15 条候选。同一个 Cron Trigger 在 UTC 00:15 同时生成日报。来源分类依据预设源类型，未经过原版 AI 验真。请从「全部白嫖」或「好价」浏览结果。原版登录、管理、其他采集源、Telegram 推送、AI 审核和依赖系统 curl 或 FlareSolverr 的源尚未移植。

## 部署

1. 克隆本 Fork，安装 Node.js 和 pnpm。运行 `pnpm install --frozen-lockfile` 和 `pnpm build --mode cloudflare`。
2. 用 `npx wrangler login` 登录 Cloudflare。运行 `npx wrangler d1 create freebie-radar-d1 --no-update-config`，把生成的数据库 ID 填入两个 Wrangler 配置。两个配置必须指向同一数据库。
3. 运行 `npx wrangler d1 migrations apply DB --remote --config wrangler.cron.toml`。
4. 创建 Pages 项目并部署。首次自建项目请把项目名改为你自己的名称，并同步修改 `wrangler.toml`。

   ```sh
   cp cloudflare/_routes.json dist/web/_routes.json
   npx wrangler pages project create freebie-radar-cn --production-branch codex/pages-d1
   npx wrangler pages deploy dist/web --project-name freebie-radar-cn --branch codex/pages-d1
   npx wrangler deploy --config wrangler.cron.toml
   ```

   PowerShell 可用 `Copy-Item cloudflare/_routes.json dist/web/_routes.json`。

5. 打开 Pages 域名的 `/health`，确认 `ok` 为 true。每小时第 15 分钟之后检查 `/api/sources` 和 `/api/items`，次日检查 `/api/digests`。

默认每月约 720 次采集，按每次写入 15 条候选估算，单日最多 360 条候选写入尝试，此外还有索引、源状态和日报写入。D1 免费额度由账户共享，列表和统计请求的读取量随数据增长和访客量变化。上线后请在 Cloudflare 仪表板查看 D1 已读取及已写入行数。
