UPDATE items SET category = 'offline'
   WHERE status = 'active'
     AND COALESCE(category, '') IN ('goods', 'other', '')
     AND (title LIKE '%现场%' OR title LIKE '%到店%' OR title LIKE '%进店%' OR title LIKE '%门店%'
          OR title LIKE '%实体店%' OR title LIKE '%快闪%' OR title LIKE '%商场%' OR title LIKE '%专柜%'
          OR title LIKE '%自提%' OR title LIKE '%试吃%' OR title LIKE '%试饮%' OR title LIKE '%派样%'
          OR title LIKE '%店庆%' OR title LIKE '%开业%' OR title LIKE '%附近%' OR title LIKE '%线下%')
     AND title NOT LIKE '%记者%' AND title NOT LIKE '%直播%' AND title NOT LIKE '%直击%'
     AND title NOT LIKE '%发布会%' AND title NOT LIKE '%峰会%' AND title NOT LIKE '%论坛%'
     AND title NOT LIKE '%通报%' AND title NOT LIKE '%签署%' AND title NOT LIKE '%白皮书%'
     AND title NOT LIKE '%备忘录%';
