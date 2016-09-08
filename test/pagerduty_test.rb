require File.expand_path('../helper', __FILE__)

class PagerdutyTest < PapertrailServices::TestCase
  def test_size_limit
    assert(payload.to_json.length > 1400, 'Test requires larger sample payload')
    svc = service(:logs, { :service_key => 'k' }, payload)
    limited_payload = svc.json_limited(payload, 1400)
    assert(limited_payload.length <= 1400)
  end

  def test_logs
    svc = service(:logs, { :service_key => 'k' }, payload)

    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_logs_with_incident_key
    svc = service(:logs, { :service_key => 'k', :incident_key => '%HOST%/PAPERTRAIL' }, payload)

    http_stubs.post '/generic/2010-04-15/create_event.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def service(*args)
    super Service::Pagerduty, *args
  end
end
