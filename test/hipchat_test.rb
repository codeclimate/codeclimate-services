require File.expand_path('../helper', __FILE__)

class TestHipChat < Test::Unit::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_coverage_change
    @stubs.post '/v1/rooms/message' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal body["auth_token"], "token"
      assert_equal body["room_id"], "123"
      assert_equal body["message"], "<b>Hello! </b>"
      assert_equal body["from"], "Code Climate"
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = CC::Service::HipChat.new(:coverage,
      { auth_token: "token", room_id: "123" },
      {})
    svc.http :adapter => [:test, @stubs]
    svc.receive

    @stubs.verify_stubbed_calls
  end
end
