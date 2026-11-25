CREATE TABLE IF NOT EXISTS settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS push_log (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    kind       TEXT NOT NULL,
    item_ids   TEXT NOT NULL DEFAULT '[]',
    text       TEXT NOT NULL DEFAULT '',
    count      INTEGER NOT NULL DEFAULT 0,
    ok         INTEGER NOT NULL DEFAULT 1,
    error      TEXT,
    created_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_push_log_time ON push_log(created_at DESC);
  ALTER TABLE items ADD COLUMN title_key TEXT;
  CREATE INDEX IF NOT EXISTS idx_items_title_key ON items(title_key);
