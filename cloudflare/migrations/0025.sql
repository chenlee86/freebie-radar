UPDATE items SET category = 'media'
   WHERE status = 'active' AND category = 'pan'
     AND (title LIKE '%更至%' OR title LIKE '%1080P%' OR title LIKE '%4K%' OR title LIKE '%剧集%'
          OR title LIKE '%动漫%' OR title LIKE '%电影%' OR title LIKE '%全集%' OR title LIKE '%年番%');

  UPDATE items SET category = 'security'
   WHERE status = 'active' AND category = 'pan' AND title LIKE '%SOCKS5%';

  UPDATE items SET category = 'other'
   WHERE status = 'active' AND category IN ('pan', 'course')
     AND (title LIKE '%签署%' OR title LIKE '%备忘录%' OR title LIKE '%论坛%' OR title LIKE '%峰会%'
          OR title LIKE '%发布会%' OR title LIKE '%暗改%' OR title LIKE '%限制加码%');
