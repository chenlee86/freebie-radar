ALTER TABLE items ADD COLUMN obtain TEXT;
  CREATE INDEX IF NOT EXISTS idx_items_obtain ON items(obtain);
