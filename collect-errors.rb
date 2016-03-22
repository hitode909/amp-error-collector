Bundler.require

require 'shellwords'
require 'json'

class SiteMap
  def uris sitemap_uri
    Enumerator.new{ |yielder|
      index = Nokogiri get sitemap_uri
      index.search('loc').each{|loc|
        page = Nokogiri get loc.content
        page.search('url').each{|item|

          uri = item.at('loc').content

          yielder << uri
        }
      }
    }
  end

  def amp_uri html_uri
    doc = Nokogiri get html_uri
    link = doc.at('link[rel="amphtml"]')
    return unless link
    link.attr('href')
  end

  protected

  def get uri
    warn "get #{uri}"
    RestClient.get(uri, :user_agent => "sketch-amp-checker")
  end
end

class Reporter
  def initialize
    @total = 0
    @success = 0
    @fail = 0
  end

  def header(sitemap_uri)
    puts sitemap_uri
  end

  def report(result)
    @total += 1
    if result['success']
      warn 'OK'
      @success += 1
    else
      if @fail == 0
        puts "\n# Errors"
      end
      @fail += 1
      puts "- #{uri}"
      result['errors'].each{|error|
        line = error['line']
        char = error['char']
        reason = error['reason']
        puts " - `#{line}:#{char}` #{reason}"
      }
    end
  end

  def summary
    puts "\n# Result"
    puts "#{@success} / #{@total} = #{(@success.to_f/@total*100).to_i}% success"
  end

end

class AmpValidator
  def validate uri
    JSON.parse(`AMP_VALIDATOR_TIMEOUT=60000 node_modules/.bin/amp-validator -o json #{Shellwords.escape uri}`)[uri]
  end
end

reporter = Reporter.new
sitemap = SiteMap.new
validator = AmpValidator.new

SITEMAP_URI = ARGV.first

reporter.header SITEMAP_URI
total = 0
sitemap.uris(SITEMAP_URI).each{|uri|
  amp_uri = sitemap.amp_uri uri
  next unless amp_uri
  result = validator.validate amp_uri
  reporter.report result
  total += 1
}

reporter.summary
