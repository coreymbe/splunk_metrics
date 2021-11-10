require 'puppet/application'
require File.dirname(__FILE__) + '/../util/splunk_metrics.rb'

# rubocop:disable Style/ClassAndModuleCamelCase
# splunk_metrics.rb
class Puppet::Application::Splunk_metrics < Puppet::Application
  include Puppet::Util::Splunk_metrics

  RUN_HELP = _("Run 'puppet splunk_metrics --help' for more details").freeze

  run_mode :master

  # Options for splunk_metrics

  option('--sourcetype SOURCETYPE') do |format|
    options[:sourcetype] = format.downcase.to_sym
  end

  option('--pe_metrics')

  option('--debug', '-d')

  def send_pe_metrics(data, sourcetype)
    timestamp = sourcetypetime(data['timestamp'])
    event_template = {
      'time' => timestamp,
      'sourcetype' => sourcetype.to_s,
      'event' => {},
    }
    data['servers'].each_key do |server|
      name = server.to_s
      content = data['servers'][server.to_s]
      content.each_key do |serv|
        event = event_template.clone
        event['host'] = name
        event['event'] = content[serv.to_s]
        event['event']['pe_console'] = pe_console
        event['event']['pe_service'] = serv.to_s
        Puppet.info 'Submitting metrics to Splunk'
        submit_request(event)
      end
    end
  end

  def main
    # This is waiting for > 5.3.0 version of metrics collector
    # data = STDIN.lines.map {|l| JSON.parse(l)}
    #
    # Below works for metrics collection < 5.3.0
    begin
      datainput = STDIN.read
    rescue StandardError => e
      Puppet.info 'Unable to parse STDIN, is it text?'
      Puppet.info e.message
      Puppet.info e.backtrace.inspect
    end

    data       = parse_metrics(datainput)
    sourcetype = options[:sourcetype].to_s

    data.each do |server|
      send_pe_metrics(server, sourcetype) if options[:pe_metrics]
    end
  end

  def parse_metrics(input)
    result = begin
               input.lines.map { |l| JSON.parse(l) }
             rescue StandardError => e
               Puppet.info 'Unable to parse json from stdin'
               Puppet.info e.message
               Puppet.info e.backtrace.inspect

               []
             end

    result
  end

  def parse_legacy_metrics(input)
    cleaned = input.gsub("\n}{\n", "\n},{\n")
    cleaned = cleaned.insert(0, '[')
    cleaned = cleaned.insert(-1, ']')

    result = begin
               JSON.parse(cleaned)
             rescue StandardError => e
               Puppet.info 'Unable to parse json from stdin'
               Puppet.info e.message
               Puppet.info e.backtrace.inspect

               []
             end

    result
  end
end
