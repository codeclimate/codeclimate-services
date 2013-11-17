require File.expand_path('../helper', __FILE__)

class TestCampfire < CC::Service::TestCase
  def test_coverage_change
    @stubs.post '/room/123/speak.json' do |env|
      body = JSON.parse(env[:body])
      assert_equal "Coverage: 80.0", body["message"]["body"]
      [200, {}, '']
    end

    receive(CC::Service::Campfire, :coverage,
      { token: "token", subdomain: "sub", room_id: "123" },
      { coverage: 80.0 })
  end
end
