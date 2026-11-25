ALTER TABLE items ADD COLUMN base_score REAL;
  UPDATE items SET base_score = score WHERE base_score IS NULL;
