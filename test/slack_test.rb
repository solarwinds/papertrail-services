require File.expand_path('../helper', __FILE__)

class SlackTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, long_payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_build_attachments
    long_payload = payload.dup
    long_payload[:events] *= 100

    slack = Service::Slack.new
    attachment = slack.build_attachments(long_payload[:events])
    assert attachment[0][:text].length < 8000
    assert attachment[0][:fallback].length < 8000
  end

  def service(*args)
    super Service::Slack, *args
  end
end
