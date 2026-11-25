UPDATE sources SET enabled = 0
   WHERE id IN (
     'tg-cn-deals',
     'rss-smzdm',
     'rss-ithome',
     'linuxdo-resource',
     'v2ex-share',
     'rss-producthunt',
     'rss-sspai',
     'rss-appinn',
     'rss-ruanyifeng',
     'rss-iapps',
     'github-free-for-dev'
   );
  UPDATE sources SET interval_sec = 2700
   WHERE id LIKE 'rss-reddit-%' AND interval_sec < 2700;
