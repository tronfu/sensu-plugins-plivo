#!/usr/bin/env ruby
#
# Sensu Handler: plivo
#
# This handler formats alerts as SMSes and sends them off to a pre-defined recipient.
#
# Copyright 2016 Tron Fu <tron@riverwatcher.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-handler'
require 'plivo'
require 'rest-client'
require 'json'

include Plivo

class PlivoSMS < Sensu::Handler
  option :json_config,
         description: 'Config Name',
         short: '-j JsonConfig',
         long: '--json_config JsonConfig',
         required: false,
         default: 'plivosms'
  
  def short_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def action_to_string
    @event['action'].eql?('resolve') ? 'RESOLVED' : 'ALERT'
  end
  
  def status_to_string
    case @event['check']['status']
    when 0
      'OK'
    when 1
      'WARNING'
    when 2
      'CRITICAL'
    else
      'UNKNOWN'
    end
  end
  
  def json_config
    @json_config ||= config[:json_config]
  end
  
  def interested_in_check?(candidate)
    (candidate['subscriptions'].nil? ||     # no subscription attribute specified
      candidate['subscriptions'].include?('all') ||
      ((candidate['subscriptions'] & @event['check']['subscribers']).size > 0) || # rubocop:disable Style/ZeroLengthPredicate
      candidate['checks'].nil? ||     # no checks were specified in the config
      candidate['checks'].include?(@event['check']['name']))
  end
  
  def passed_status_cutoff?(candidate)
    (@event['action'].eql?('resolve') || 
      (candidate['cutoff'] || 2) <= @event['check']['status'])  # default to only send sms on critical
  end
  
  def handle
    auth_id = settings[json_config]['id']
    auth_token = settings[json_config]['token']
    from_number = settings[json_config]['number']
    candidates = settings[json_config]['recipients']
    url = settings[json_config]['url']
    short = settings[json_config]['short'] || false
    ignore_resolve = settings[json_config]['ignore_resolve'] || false

    return if @event['action'].eql?('resolve') && ignore_resolve

    raise 'Please define a valid Plivo authentication set to use this handler' unless auth_id && auth_token && from_number
    raise 'Please define a valid set of SMS recipients to use this handler' if candidates.nil? || candidates.empty?

    recipients = []
    candidates.each do |mobile, candidate|
      next unless interested_in_check?(candidate) && passed_status_cutoff?(candidate)
      recipients << mobile
    end

    message = if short
                "Sensu #{action_to_string}: #{@event['check']['output']}"
              else
                "Sensu #{action_to_string}: #{short_name} (#{@event['client']['address']}) #{@event['check']['output']}"
              end

    message[157..message.length] = '...' if message.length > 160

    plivo = RestAPI.new(auth_id, auth_token)

    recipients.each do |recipient|
      params = {
        'src' => from_number, # Sender's phone number with country code
        'dst' => recipient,   # Receiver's phone Number with country code
        'text' => message     # SMS Text Message
      }
      params.merge!(
        {
          'url' => url,       # The URL to which with the status of the message is sent
          'method' => 'POST' # The method used to call the url
        }
      ) unless url.to_s.empty?
      
      response = plivo.send_message(params)
      
      if response[1]['error'].nil?
        puts "Notified #{recipient} for #{action_to_string}"
      else
        puts "Failure detected while using Plivo to notify on event: #{response[1]['error']}"
      end
    end
  end
end
