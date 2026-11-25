UPDATE items SET category = 'pan'
   WHERE status = 'active'
     AND COALESCE(category, '') IN ('media', 'cloud', 'other', '')
     AND title NOT LIKE '%浏览器%'
     AND (title LIKE '%网盘%' OR title LIKE '%云盘%' OR title LIKE '%阿里云盘%' OR title LIKE '%百度网盘%'
          OR title LIKE '%夸克%' OR title LIKE '%提取码%' OR title LIKE '%转存%' OR title LIKE '%115网盘%');

  UPDATE items SET category = 'course'
   WHERE status = 'active'
     AND COALESCE(category, '') IN ('edu', 'other', '')
     AND (title LIKE '%网课%' OR title LIKE '%课程%' OR title LIKE '%公开课%' OR title LIKE '%训练营%'
          OR title LIKE '%课件%' OR title LIKE '%讲义%' OR title LIKE '%视频教程%');
