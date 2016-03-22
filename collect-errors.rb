Bundler.require

require 'shellwords'
require 'json'
require 'logger'

LOG = Logger.new(STDERR)

if ENV['AMP_ERROR_COLLECTOR_DEBUG']
  LOG.level = Logger::DEBUG
else
  LOG.level = Logger::INFO
end

class SiteMap
  def uris sitemap_uri
    Enumerator.new{ |yielder|
      index = Nokogiri get sitemap_uri
      index.search('sitemap loc').each{|loc|
        uris(loc.content).each {|uri|
          yielder << uri
        }
      }
      index.search('url loc').each{|loc|
        uri = loc.content
        yielder << uri
      }
    }
  end

  def amp_uri html_uri
    LOG.debug "get AMP uri for #{html_uri}"
    doc = Nokogiri get html_uri
    link = doc.at('link[rel="amphtml"]')
    return unless link
    href = link.attr('href')
    return unless href
    LOG.debug "found #{href}"
    href
  end

  protected

  def get uri
    LOG.debug "get #{uri}"
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
    puts "Error Report of #{sitemap_uri}"
  end

  def report(uri, result)
    @total += 1
    if result['success']
      LOG.info "success"
      @success += 1
    else
      LOG.info "failed"
      LOG.debug result.inspect
      if @fail == 0
        puts "\n# Errors"
      end
      @fail += 1
      puts "- #{uri}"
      if result['errors'].length > 0
        result['errors'].each{|error|
          line = error['line']
          char = error['char']
          reason = error['reason']
          puts " - `#{line}:#{char}` #{reason}"
        }
      else
        puts " - Doesn't seem to be an AMP page"
      end
    end
  end

  def summary
    puts "\n# Result"
    if @total > 0
      puts "#{@success} / #{@total} = #{(@success.to_f/@total*100).to_i}% success"
    else
      puts "AMP pages not found"
    end
  end

end

class AmpValidator
  def validate uri
    LOG.info "validate #{uri}"
    Retryable.retryable(tries: 10, on: JSON::ParserError) do
      JSON.parse(`AMP_VALIDATOR_TIMEOUT=60000 node_modules/.bin/amp-validator -o json #{Shellwords.escape uri}`)[uri]
    end
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
  reporter.report amp_uri, result
  total += 1
}

reporter.summary
