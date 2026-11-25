ALTER TABLE items ADD COLUMN ai_reviewed_at TEXT;
  UPDATE items SET ai_reviewed_at = COALESCE(last_seen_at, first_seen_at) WHERE ai IS NOT NULL AND ai_reviewed_at IS NULL;
  CREATE INDEX IF NOT EXISTS idx_items_ai_reviewed ON items(ai_reviewed_at DESC);
