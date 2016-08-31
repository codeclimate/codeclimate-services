require File.expand_path('../helper', __FILE__)

class TestJira < CC::Service::TestCase
  def test_successful_receive
    response = assert_jira_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
    assert_equal "10000", response[:id]
  end

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

  def test_issue
    payload = {
      issue: {
        "check_name" => "Style/LongLine",
        "description" => "Line is too long [1000/80]"
      },
      constant_name: "foo.rb",
      details_url: "http://example.com/repos/id/foo.rb#issue_123"
    }

    assert_jira_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123"
    )
  end

  def test_receive_test
    @stubs.post '/rest/api/2/issue' do |env|
      [200, {}, '{"id": 12345, "key": "CC-123", "self": "http://foo.bar"}']
    end

    response = receive_event(name: "test")

    assert_equal "Ticket <a href='https://foo.com/browse/CC-123'>12345</a> created.", response[:message]
  end

  private

  def assert_jira_receives(event_data, title, ticket_body)
    @stubs.post '/rest/api/2/issue' do |env|
      body = JSON.parse(env[:body])
      assert_equal "Basic Zm9vOmJhcg==", env[:request_headers]["Authorization"]
      assert_equal title, body["fields"]["summary"]
      assert_equal ticket_body, body["fields"]["description"]
      assert_equal "Task", body["fields"]["issuetype"]["name"]
      [200, {}, '{"id":"10000"}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Jira,
      { domain: "foo.com", username: "foo", password: "bar", project_id: "100" },
      event_data || event(:quality, from: "C", to: "D")
    )
  end
end
