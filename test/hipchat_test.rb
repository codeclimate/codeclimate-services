require File.expand_path('../helper', __FILE__)

class TestHipChat < CC::Service::TestCase
  def test_coverage_change
    @stubs.post '/v1/rooms/message' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "token", body["auth_token"]
      assert_equal "123", body["room_id"]
      assert_equal "<b>Coverage:</b> 80.0", body["message"]
      [200, {}, '']
    end

    receive(CC::Service::HipChat, :coverage,
      { auth_token: "token", room_id: "123" },
      { coverage: 80.0 })
  end
end
