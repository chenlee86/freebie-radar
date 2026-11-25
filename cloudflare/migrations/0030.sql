UPDATE sources SET config = json_set(config, '$.fixedCategory', 'pan')
   WHERE id = 'linuxdo-resource' AND json_valid(config)
     AND json_type(config, '$.fixedCategory') IS NULL;
  UPDATE items SET category = 'pan',
    ai = CASE WHEN json_valid(ai) THEN CASE WHEN json_type(ai) = 'object' THEN json_set(ai, '$.category', 'pan') ELSE ai END ELSE ai END
   WHERE source_id = 'linuxdo-resource' AND
     NOT EXISTS (
       SELECT 1 FROM sources WHERE id = 'linuxdo-resource' AND json_valid(config)
         AND json_type(config, '$.fixedCategory') IS NOT NULL
         AND json_extract(config, '$.fixedCategory') IS NOT 'pan'
     );
