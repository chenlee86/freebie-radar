ALTER TABLE items ADD COLUMN ai_keep INTEGER;
  CREATE INDEX IF NOT EXISTS idx_items_ai_keep ON items(ai_keep);
  UPDATE items SET ai_keep = json_extract(ai, '$.keep') WHERE ai IS NOT NULL AND ai_keep IS NULL;
