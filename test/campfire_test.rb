require File.expand_path('../helper', __FILE__)

class TestCampfire < CC::Service::TestCase
  def test_config
    assert_raises CC::Service::ConfigurationError do
      service(CC::Service::Campfire, :coverage, {},{})
    end
  end

  def test_coverage_improved
    expected_message = "[Code Climate][Rails] :sunny: Test coverage has improved to 90.2% (+10.2%). (http://codeclimate.com/rails/compare)"
    @stubs.post '/room/123/speak.json' do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_message, body["message"]["body"]
      [200, {}, '']
    end

    receive(CC::Service::Campfire, :coverage,
      { token: "token", subdomain: "sub", room_id: "123" },
      {
        repo_name: "Rails",
        covered_percent: 90.2,
        previous_covered_percent: 80.0,
        details_url: "http://codeclimate.com/rails/compare"
      })
  end

  def test_coverage_declined
    expected_message = "[Code Climate][jQuery] :umbrella: Test coverage has declined to 88.6% (-6.0%). (http://codeclimate.com/rails/compare)"
    @stubs.post '/room/123/speak.json' do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_message, body["message"]["body"]
      [200, {}, '']
    end

    receive(CC::Service::Campfire, :coverage,
      { token: "token", subdomain: "sub", room_id: "123" },
      {
        repo_name: "jQuery",
        covered_percent: 88.6,
        previous_covered_percent: 94.6,
        details_url: "http://codeclimate.com/rails/compare"
      })
  end
end
