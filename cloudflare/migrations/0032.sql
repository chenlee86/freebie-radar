CREATE INDEX IF NOT EXISTS idx_items_status_time
    ON items(status, COALESCE(published_at, first_seen_at) DESC);
