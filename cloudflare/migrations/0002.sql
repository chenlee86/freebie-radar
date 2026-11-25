CREATE TABLE IF NOT EXISTS subscriptions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    keyword     TEXT NOT NULL UNIQUE,
    created_at  TEXT NOT NULL,
    last_hit_at TEXT

  );
  CREATE INDEX IF NOT EXISTS idx_subs_keyword ON subscriptions(keyword);
