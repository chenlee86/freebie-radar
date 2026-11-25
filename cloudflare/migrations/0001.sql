CREATE TABLE IF NOT EXISTS sources (
    id           TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    kind         TEXT NOT NULL,
    enabled      INTEGER NOT NULL DEFAULT 1,
    config       TEXT NOT NULL DEFAULT '{}',
    cursor       TEXT,
    last_run_at  TEXT,
    last_status  TEXT,
    last_error   TEXT,
    created_at   TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS runs (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id    TEXT NOT NULL,
    started_at   TEXT NOT NULL,
    finished_at  TEXT,
    status       TEXT NOT NULL DEFAULT 'running',
    fetched      INTEGER NOT NULL DEFAULT 0,
    inserted     INTEGER NOT NULL DEFAULT 0,
    skipped      INTEGER NOT NULL DEFAULT 0,
    duration_ms  INTEGER,
    error        TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_runs_source ON runs(source_id, started_at DESC);

  CREATE TABLE IF NOT EXISTS items (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id     TEXT NOT NULL,
    external_id   TEXT NOT NULL,
    url           TEXT NOT NULL,
    url_key       TEXT NOT NULL,
    title         TEXT NOT NULL,
    summary       TEXT,
    author        TEXT,
    category      TEXT,
    tags          TEXT NOT NULL DEFAULT '[]',
    score         REAL NOT NULL DEFAULT 0,
    expires_at    TEXT,
    published_at  TEXT,
    raw           TEXT NOT NULL DEFAULT '{}',
    status        TEXT NOT NULL DEFAULT 'active',
    starred       INTEGER NOT NULL DEFAULT 0,
    ai            TEXT,
    first_seen_at TEXT NOT NULL,
    last_seen_at  TEXT NOT NULL,
    UNIQUE(source_id, external_id)
  );
  CREATE UNIQUE INDEX IF NOT EXISTS idx_items_url_key ON items(url_key);
  CREATE INDEX IF NOT EXISTS idx_items_published ON items(published_at DESC);
  CREATE INDEX IF NOT EXISTS idx_items_score ON items(score DESC);
  CREATE INDEX IF NOT EXISTS idx_items_category ON items(category);
  CREATE INDEX IF NOT EXISTS idx_items_status ON items(status);

  CREATE TABLE IF NOT EXISTS digests (
    date        TEXT PRIMARY KEY,
    item_ids    TEXT NOT NULL DEFAULT '[]',
    payload     TEXT NOT NULL DEFAULT '{}',
    created_at  TEXT NOT NULL,
    pushed_at   TEXT
  );
