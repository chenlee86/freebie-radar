CREATE TABLE IF NOT EXISTS block_rules (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern    TEXT NOT NULL,
    mode       TEXT NOT NULL DEFAULT 'keyword',
    scope      TEXT NOT NULL DEFAULT 'all',
    enabled    INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL
  );
  CREATE UNIQUE INDEX IF NOT EXISTS idx_block_unique ON block_rules(pattern, scope);
  ALTER TABLE items ADD COLUMN read_at TEXT;
