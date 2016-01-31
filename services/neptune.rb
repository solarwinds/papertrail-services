# encoding: utf-8

class Service::Neptune < Service
  def json_limited(payload, size_limit)
    ret = payload.to_json

    while ret.length > size_limit
      # This should only run once in the vast majority of cases, but the loop
      # is necessary for pathological inputs
      estimate = 0.9 * size_limit / ret.length
      new_length = (payload[:events].length * estimate).floor
      payload[:events] = payload[:events][0 .. new_length - 1]
      ret = payload.to_json
    end

    ret
  end

  def receive_logs
    raise_config_error 'Missing Neptune API key' if
      settings[:api_key].to_s.empty?

    size_limit= 5242880 # Neptune specified 5mb as of Feb 2016

    url = "https://www.neptune.io/api/v1/trigger/channel/papertrail/#{settings[:api_key]}"
    resp = http_post url, json_limited(payload, size_limit)
    resp = http_post url do |req|
      req.headers = {
        'Content-Type' => 'application/json'
      }
      req.body = json_limited(payload, size_limit)
    end

    unless resp.success?
      puts "Neptune: #{resp.body.to_s}"
      raise_config_error "Failed to post to Victorops"
    end
  end
end
