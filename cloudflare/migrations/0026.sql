UPDATE items SET category = 'course'
   WHERE status = 'active' AND category = 'pan'
     AND (title LIKE '%课程%' OR title LIKE '%讲义%' OR title LIKE '%训练班%' OR title LIKE '%讲完%'
          OR title LIKE '%节短课%' OR title LIKE '%实战篇%' OR title LIKE '%一套书%' OR title LIKE '%电子书%');
