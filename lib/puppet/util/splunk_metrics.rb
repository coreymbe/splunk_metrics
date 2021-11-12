require 'puppet'
require 'puppet/util'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'yaml'
require 'json'
require 'time'

# rubocop:disable Style/ClassAndModuleCamelCase
# splunk_metrics.rb
module Puppet::Util::Splunk_metrics
  def settings
    return @settings if @settings
    @settings_file = Puppet[:confdir] + '/splunk_metrics/splunk_metrics.yaml'

    @settings = YAML.load_file(@settings_file)
  end

  def create_http
    splunk_url = get_splunk_url
    @uri = URI.parse(splunk_url)
    timeout = settings['timeout'] || '1'
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.open_timeout = timeout.to_i
    http.read_timeout = timeout.to_i
    http.use_ssl = @uri.scheme == 'https'
    if http.use_ssl?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http
  end

  def submit_request(body)
    token = settings['token'] || raise(Puppet::Error, 'Must provide token')
    http = create_http
    req = Net::HTTP::Post.new(@uri.path.to_str)
    req.add_field('Authorization', "Splunk #{token}")
    req.add_field('Content-Type', 'application/json')
    req.content_type = 'application/json'
    req.body = body.to_json
    http.request(req)
  end

  private

  def get_splunk_url
    settings['url'] || raise(Puppet::Error, 'Must provide url parameter to splunk class')
  end

  def pe_console
    settings['pe_console']
  end

  # standard function to make sure we're using the same time format our sourcetypes are set to parse
  def sourcetypetime(time, duration = 0)
    parsed_time = time.is_a?(String) ? Time.parse(time) : time
    total = Time.parse((parsed_time + duration).iso8601(3))
    '%10.3f' % total.to_f
  end
end
