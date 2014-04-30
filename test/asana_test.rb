require File.expand_path('../helper', __FILE__)

class TestAsana < CC::Service::TestCase
  def test_quality
    assert_asana_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate - https://codeclimate.com/repos/1/feed"
    )
  end

  def test_vulnerability
    assert_asana_receives(
      event(:vulnerability, vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }]),
      "New critical issue found in app/user.rb line 120 - https://codeclimate.com/repos/1/feed"
    )
  end

  private

  def assert_asana_receives(event_data, name)
    @stubs.post '/api/1.0/tasks' do |env|
      body = JSON.parse(env[:body])
      data = body["data"]

      assert_equal "1",             data["workspace"]
      assert_equal "2",             data["projects"].first
      assert_equal "jim@asana.com", data["assignee"]
      assert_equal name,            data["name"]

      [200, {}, '{"data":{"id":{}}}']
    end

    receive(
      CC::Service::Asana,
      { api_key: "abc123", workspace_id: "1", project_id: "2", assignee: "jim@asana.com" },
      event_data
    )
  end
end
