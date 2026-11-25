UPDATE items
     SET kind = 'news'
   WHERE kind = 'info'
    AND category IN ('headline', 'world');
