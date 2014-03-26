require File.expand_path('../helper', __FILE__)

class TestPivotalTracker < CC::Service::TestCase
  def test_quality
    assert_pivotal_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
  end

  private

  def assert_pivotal_receives(event_data, name, description)
    @stubs.post 'services/v3/projects/123/stories' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "token", env[:request_headers]["X-TrackerToken"]
      assert_equal name, body["story[name]"]
      assert_equal description, body["story[description]"]
      [200, {}, '']
    end

    receive(
      CC::Service::PivotalTracker,
      { api_token: "token", project_id: "123" },
      event_data
    )
  end
end
