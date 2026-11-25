CREATE TABLE IF NOT EXISTS item_classification_overrides (
    item_id INTEGER PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
    category TEXT,
    kind TEXT,
    note TEXT NOT NULL DEFAULT '',
    updated_at TEXT NOT NULL,
    CHECK(category IS NOT NULL OR kind IS NOT NULL)
  );
  CREATE TRIGGER IF NOT EXISTS enforce_manual_item_classification
  AFTER UPDATE OF category, kind ON items
  WHEN EXISTS (
    SELECT 1 FROM item_classification_overrides o WHERE o.item_id = NEW.id
      AND ((o.category IS NOT NULL AND NEW.category IS NOT o.category)
        OR (o.kind IS NOT NULL AND NEW.kind IS NOT o.kind))
  )
  BEGIN
    UPDATE items SET
      category = COALESCE((SELECT category FROM item_classification_overrides WHERE item_id = NEW.id), category),
      kind = COALESCE((SELECT kind FROM item_classification_overrides WHERE item_id = NEW.id), kind)
      WHERE id = NEW.id;
  END;
  CREATE TRIGGER IF NOT EXISTS apply_manual_item_classification
  AFTER INSERT ON item_classification_overrides
  BEGIN
    UPDATE items SET category = COALESCE(NEW.category, category), kind = COALESCE(NEW.kind, kind) WHERE id = NEW.item_id;
  END;
  CREATE TRIGGER IF NOT EXISTS update_manual_item_classification
  AFTER UPDATE OF category, kind ON item_classification_overrides
  BEGIN
    UPDATE items SET category = COALESCE(NEW.category, category), kind = COALESCE(NEW.kind, kind) WHERE id = NEW.item_id;
  END;
