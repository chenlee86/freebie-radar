UPDATE items SET category = 'other'
   WHERE status = 'active' AND category = 'offline'
     AND (COALESCE(kind, '') IN ('news', 'info', 'noise')
          OR title LIKE '%不合格%' OR title LIKE '%抽检%' OR title LIKE '%通报%'
          OR title LIKE '%有吗%' OR title LIKE '%我想%' OR title LIKE '%求租%'
          OR title LIKE '%转租%' OR title LIKE '%租房%' OR title LIKE '%合租%'
          OR title LIKE '%记者%' OR title LIKE '%发布会%' OR title LIKE '%峰会%');
