# AMP Error Collector

Crawl AMP pages from sitemap.xml and report errors.

```
bundle install
npm install
bundle exec -- ruby collect-errors.rb SITEMAP_XMP_URI | tee a.md
```

# debug

```
AMP_ERROR_COLLECTOR_DEBUG=1 bundle exec -- ruby collect-errors.rb SITEMAP_XMP_URI
```

