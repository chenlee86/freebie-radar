CREATE INDEX IF NOT EXISTS idx_items_feed ON items(status, ai_keep, score DESC);
  CREATE INDEX IF NOT EXISTS idx_items_score ON items(score DESC);
