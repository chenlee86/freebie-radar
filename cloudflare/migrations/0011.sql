CREATE INDEX IF NOT EXISTS idx_items_effective_time ON items(COALESCE(published_at, first_seen_at));
