require File.expand_path('../helper', __FILE__)

class MattermostTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :mattermost_url => "https://mattermost.domain.com/hooks/HookID" }, payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    long_payload[:events] *= 100

    svc = service(:logs, { :mattermost_url => "https://mattermost.domain.com/hooks/HookID" }, long_payload)

    http_stubs.post '/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_build_attachments
    long_payload = payload.dup
    long_payload[:events] *= 100

    slack = Service::Mattermost.new
    attachment = slack.build_attachments(long_payload[:events])
    assert attachment[0][:text].length < 8000
    assert attachment[0][:fallback].length < 8000
  end

  def test_no_messages
    empty_payload = payload.dup
    empty_payload[:events] = []

    svc = service(:logs, { :mattermost_url => "https://mattermost.domain.com/hooks/HookID" }, empty_payload)

    post = false
    http_stubs.post '/hooks/incoming-webhook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def test_dont_display_messages
    svc = service(:logs, { :dont_display_messages => 1, :mattermost_url => "https://mattermost.domain.com/hooks/HookID" }, payload)

    post = false
    http_stubs.post '/hooks/incoming-webhook' do |env|
      post = true
      body = JSON(env[:body])

      assert !body.has_key?('attachments'), 'Expected no attachments without events'

      [200, {}, '']
    end

    svc.receive_logs

    assert post, 'Expected post to service webhook'
  end

  def service(*args)
    super Service::Mattermost, *args
  end
end
