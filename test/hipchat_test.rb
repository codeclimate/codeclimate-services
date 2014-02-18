require File.expand_path('../helper', __FILE__)

class TestHipChat < CC::Service::TestCase
  def test_coverage_improved
    expected_message = "[Rails] <a href=\"https://codeclimate.com/repos/1/feed\">"
    expected_message << "Test coverage</a> has improved to 90.2% (+10.2%)"
    expected_message << " (<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    @stubs.post '/v1/rooms/message' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "token", body["auth_token"]
      assert_equal "123", body["room_id"]
      assert_equal "green", body["color"]
      assert_equal expected_message, body["message"]
      [200, {}, '']
    end

    receive(CC::Service::HipChat, :coverage,
      { auth_token: "token", room_id: "123" },
      {
        repo_name: "Rails",
        covered_percent: 90.2,
        previous_covered_percent: 80.0,
        details_url: "https://codeclimate.com/repos/1/feed",
        compare_url: "https://codeclimate.com/repos/1/compare"
      })
  end

  def test_coverage_declined_without_compare_url
    expected_message = "[Rails] <a href=\"https://codeclimate.com/repos/1/feed\">"
    expected_message << "Test coverage</a> has declined to 80.0% (-6.2%)"
    @stubs.post '/v1/rooms/message' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "token", body["auth_token"]
      assert_equal "123", body["room_id"]
      assert_equal "red", body["color"]
      assert_equal expected_message, body["message"]
      [200, {}, '']
    end

    receive(CC::Service::HipChat, :coverage,
      { auth_token: "token", room_id: "123" },
      {
        repo_name: "Rails",
        covered_percent: 80.0,
        previous_covered_percent: 86.2,
        details_url: "https://codeclimate.com/repos/1/feed",
      })
  end
end
