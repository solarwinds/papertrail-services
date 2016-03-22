# encoding: utf-8
class Service::Slack < Service
  def receive_logs
    raise_config_error 'Missing slack webhook' if settings[:slack_url].to_s.empty?
    raise_config_error "Slack webhook must point to Slack endpoint domain, typically slack.com" unless settings[:slack_url].to_s.match(/slack\.com|transposer\.io/)

    dont_display_messages = settings[:dont_display_messages].to_i == 1

    events  = payload[:events]
    message = %{"#{payload[:saved_search][:name]}" search found #{Pluralize.new('match', :count => payload[:events].length)} — <#{payload[:saved_search][:html_search_url]}|#{payload[:saved_search][:html_search_url]}>}

    data = {
      :text => message,
      :parse => 'none'
    }

    if events.present? && !dont_display_messages
      attachment = format_content(events)
      data[:attachments] = [
        {
          :text => attachment,
          :mrkdwn_in => ["text"]
        }
      ]
    end

    http.headers['content-type'] = 'application/json'
    response = http_post settings[:slack_url], data.to_json

    unless response.success?
      puts "slack: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit logs"
    end
  end

  # Slack truncates attachments at 8000 bytes
  def format_content(events, limit = 7500)
    body = ''

    events.each do |event|
      message = syslog_format(event) + "\n"
      if (body.length + message.length) < limit
        body << message
      else
        break
      end
    end

    # Provide some basic escaping of ``` in messages
    body = body.gsub('```', '` ` `')

    "```" + body + "```"
  end
end
