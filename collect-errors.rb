Bundler.require

require 'shellwords'
require 'json'

class SiteMap
  def get_amp_entry_uris sitemap_index_uri
    get_entry_uris(sitemap_index_uri).map{|uri|
      amp_uri uri
    }.compact
  end

  def get_entry_uris sitemap_index_uri
    uris = []
    index = Nokogiri get sitemap_index_uri
    index.search('loc').each{|loc|
      page = Nokogiri get loc.content
      page.search('url').each{|item|

        uri = item.at('loc').content

        uris.push uri
        return uris if uris.length > 3
      }
    }
    uris
  end

  def amp_uri html_uri
    doc = Nokogiri get html_uri
    link = doc.at('link[rel="amphtml"]')
    return unless link
    link.attr('href')
  end

  def get uri
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
p sitemap.get_amp_entry_uris(SITEMAP_URI)
sitemap.get_amp_entry_uris(SITEMAP_URI).each{|uri|
  warn uri
  result = validator.validate uri
  reporter.report result
}

reporter.summary
