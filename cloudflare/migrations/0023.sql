UPDATE items SET category = 'other'
   WHERE status = 'active'
     AND category = 'pan'
     AND title NOT LIKE '%网盘%'
     AND title NOT LIKE '%云盘%'
     AND title NOT LIKE '%提取码%'
     AND title NOT LIKE '%转存%'
     AND title NOT LIKE '%夸克%';
