import { mkdir, readFile, writeFile } from "node:fs/promises";

const base = new URL("../", import.meta.url);
const db = await readFile(new URL("src/server/db.ts", base), "utf8");
const migrations = db.split("const MIGRATIONS: string[] = [")[1]?.split(/^\];/m)[0];
if (!migrations) throw new Error("SQLite migrations not found");
const statements = [...migrations.matchAll(/`([^`]+)`/g)];
if (!statements.length || statements.some(([, sql]) => sql.includes("${"))) {
  throw new Error("Unsupported SQLite migration format");
}
await mkdir(new URL("cloudflare/migrations/", base), { recursive: true });
for (const [index, [, sql]] of statements.entries()) {
  const name = String(index + 1).padStart(4, "0");
  await writeFile(new URL("cloudflare/migrations/" + name + ".sql", base), sql.trim() + "\n");
}
