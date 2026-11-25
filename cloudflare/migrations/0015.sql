ALTER TABLE items ADD COLUMN kind TEXT;
  ALTER TABLE items ADD COLUMN ai_quality INTEGER;
  CREATE INDEX IF NOT EXISTS idx_items_kind ON items(kind);
  UPDATE items
     SET kind = CASE
       WHEN ai_keep = 0 THEN 'noise'
       WHEN category = 'opensource' THEN 'opensource'
       WHEN obtain = 'paid' THEN 'deal'
       ELSE 'freebie'
     END
   WHERE kind IS NULL;
  UPDATE items
     SET ai_quality = json_extract(ai, '$.quality')
   WHERE ai IS NOT NULL AND ai_quality IS NULL;
