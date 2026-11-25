ALTER TABLE items ADD COLUMN canonical_id INTEGER;
  CREATE INDEX IF NOT EXISTS idx_items_canonical_id ON items(canonical_id);
