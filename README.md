# AMP Error Collector

Crawl AMP pages from sitemap.xml and report errors.

```
bundle install
npm install
bundle exec -- ruby collect-errors.rb SITEMAP_XMP_URI | tee a.md
```

Example output:

- https://gist.github.com/hitode909/0872cb73c5da2aaf37838f50bf7ec599

# debug

```
AMP_ERROR_COLLECTOR_DEBUG=1 bundle exec -- ruby collect-errors.rb SITEMAP_XMP_URI
```

