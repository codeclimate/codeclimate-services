require File.expand_path('../helper', __FILE__)

class TestHipChat < CC::Service::TestCase
  def test_coverage_change
    @stubs.post '/services/v3/projects/123/stories' do |env|
      assert_equal "token", env[:request_headers]["X-TrackerToken"]
      [200, {}, '']
    end

    receive(CC::Service::PivotalTracker, :unit,
      { api_token: "token", project_id: "123" },
      { name: "User" })
  end
end
