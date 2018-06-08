class Service::Beacon < Service
  def post_data(body)
    headers = {
      'X-SWI-ALERT-API-KEY' => settings[:api_key]
    }
    
    resp = http_post("http://localhost:6789/alerts", body.to_json, headers)

    if resp.success?
      resp
    else
      error_body = Yajl::Parser.parse(resp.body) rescue nil
      if error_body
        raise_config_error("Unable to send: #{error_body['errors'].join(", ")}")
      else
        puts "beacon: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
      end
    end
  end

  def receive_logs
    search_url  = payload[:saved_search][:html_search_url]
    description = settings[:description]
    saved_search_id = payload[:saved_search][:id]
    frequency   = frequency_phrase(payload[:frequency])

    body = {
      alert_definition_id: "papertrail-#{saved_search_id}",
      alert_instance_id: "papertrail-#{saved_search_id}-#{payload[:max_id]}",
      alert_instance_origination_time: Time.now.utc.to_i,
      description: payload[:saved_search][:name],
      url: payload[:saved_search][:html_search_url]
    }

    # Property bag is a JSON blob that gets stored in Beacon along with the alert
    body[:property_bag] = {
      alert_id: "#{payload[:saved_search][:id]}",
      alert_name: payload[:saved_search][:name],
      alert_description: payload[:saved_search][:name],
      frequency: payload[:frequency],
      # This could be a large # of events
      events: payload[:events].to_json
    }

    post_data(body)
  end
end
