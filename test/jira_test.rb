require File.expand_path('../helper', __FILE__)

class TestJira < CC::Service::TestCase
  def test_quality
    assert_jira_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
  end

  def test_vulnerability
    assert_jira_receives(
      event(:vulnerability, vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed"
    )
  end

  private

  def assert_jira_receives(event_data, title, ticket_body)
    @stubs.post '/rest/api/2/issue' do |env|
      body = JSON.parse(env[:body])
      assert_equal "Basic Zm9vOmJhcg==", env[:request_headers]["Authorization"]
      assert_equal title, body["fields"]["summary"]
      assert_equal ticket_body, body["fields"]["description"]
      [200, {}, '{"ticket":{}}']
    end

    receive(
      CC::Service::Jira,
      { domain: "foo.com", username: "foo", password: "bar", project_id: "100" },
      event_data
    )
  end
end
