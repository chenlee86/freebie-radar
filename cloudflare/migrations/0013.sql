UPDATE sources SET enabled = 0
   WHERE id IN (
     'rss-hnrss',
     'rss-9to5toys',
     'rss-52pojie',
     'rss-fuliba',
     'github-public-apis',
     'github-awesome-ai',
     'github-selfhosted'
   );
