CREATE TABLE IF NOT EXISTS users (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    linuxdo_id     INTEGER NOT NULL UNIQUE,
    username       TEXT NOT NULL,
    name           TEXT,
    avatar_url     TEXT,
    trust_level    INTEGER NOT NULL DEFAULT 0,
    disabled       INTEGER NOT NULL DEFAULT 0,
    rss_token      TEXT NOT NULL UNIQUE,
    invited_by_id  INTEGER,
    created_at     TEXT NOT NULL,
    last_login_at  TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS sessions (
    id         TEXT PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
  CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

  CREATE TABLE IF NOT EXISTS invite_codes (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    code       TEXT NOT NULL UNIQUE,
    max_uses   INTEGER NOT NULL DEFAULT 1,
    used_count INTEGER NOT NULL DEFAULT 0,
    disabled   INTEGER NOT NULL DEFAULT 0,
    note       TEXT,
    expires_at TEXT,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS invite_redemptions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    invite_id   INTEGER NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    redeemed_at TEXT NOT NULL,
    UNIQUE(invite_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS user_item_states (
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id    INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    hidden     INTEGER NOT NULL DEFAULT 0,
    starred    INTEGER NOT NULL DEFAULT 0,
    read_at    TEXT,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (user_id, item_id)
  );
  CREATE INDEX IF NOT EXISTS idx_uis_user_hidden ON user_item_states(user_id, hidden);
  CREATE INDEX IF NOT EXISTS idx_uis_user_starred ON user_item_states(user_id, starred);
  CREATE INDEX IF NOT EXISTS idx_uis_item_starred ON user_item_states(item_id, starred);

  CREATE TABLE IF NOT EXISTS user_block_rules (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern    TEXT NOT NULL,
    mode       TEXT NOT NULL DEFAULT 'keyword',
    scope      TEXT NOT NULL DEFAULT 'all',
    enabled    INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    UNIQUE(user_id, pattern, scope)
  );

  CREATE TABLE IF NOT EXISTS user_subscriptions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    keyword     TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    last_hit_at TEXT,
    UNIQUE(user_id, keyword)
  );

  CREATE TABLE IF NOT EXISTS user_push_configs (
    user_id           INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    enabled           INTEGER NOT NULL DEFAULT 0,
    bot_token_enc     TEXT,
    bot_token_mask    TEXT,
    chat_id           TEXT NOT NULL DEFAULT '',
    settings          TEXT NOT NULL DEFAULT '{}',
    use_global_blocks INTEGER NOT NULL DEFAULT 1,
    daily_enabled     INTEGER NOT NULL DEFAULT 0,
    consecutive_fails INTEGER NOT NULL DEFAULT 0,
    last_error        TEXT,
    last_flush_at     TEXT,
    last_pushed_at    TEXT,
    updated_at        TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS user_push_deliveries (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id    INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    title_key  TEXT,
    status     TEXT NOT NULL,
    reason     TEXT,
    route_name TEXT,
    queued_at  TEXT NOT NULL,
    sent_at    TEXT,
    UNIQUE(user_id, item_id)
  );
  CREATE INDEX IF NOT EXISTS idx_upd_user_status ON user_push_deliveries(user_id, status, queued_at);
  CREATE INDEX IF NOT EXISTS idx_upd_user_sent ON user_push_deliveries(user_id, sent_at DESC);

  CREATE TABLE IF NOT EXISTS user_push_logs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind       TEXT NOT NULL,
    item_ids   TEXT NOT NULL DEFAULT '[]',
    text       TEXT NOT NULL DEFAULT '',
    count      INTEGER NOT NULL DEFAULT 0,
    ok         INTEGER NOT NULL DEFAULT 1,
    error      TEXT,
    reason     TEXT,
    created_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_upl_user_time ON user_push_logs(user_id, created_at DESC);
