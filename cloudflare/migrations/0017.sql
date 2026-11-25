INSERT OR IGNORE INTO block_rules (pattern, mode, scope, enabled, created_at)
  SELECT DISTINCT TRIM(je.value), 'keyword', 'all', 1, datetime('now')
    FROM settings s, json_each(s.value, '$.customNoiseKeywords') je
   WHERE s.key = 'ai'
     AND json_valid(s.value)
     AND json_type(s.value, '$.customNoiseKeywords') = 'array'
     AND TRIM(je.value) != '';
  UPDATE settings
     SET value = json_set(value, '$.customNoiseKeywords', json('[]'))
   WHERE key = 'ai'
     AND json_valid(value)
     AND json_type(value, '$.customNoiseKeywords') = 'array';
