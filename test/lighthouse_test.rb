require File.expand_path("../helper", __FILE__)

class TestLighthouse < CC::Service::TestCase
  def test_quality
    response = assert_lighthouse_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
    assert_equal "123", response[:id]
    assert_equal "http://lighthouse.com/projects/123/tickets/123.json",
      response[:url]
  end

  def test_vulnerability
    assert_lighthouse_receives(
      event(:vulnerability, vulnerabilities: [{
              "warning_type" => "critical",
              "location" => "app/user.rb line 120",
            }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed",
    )
  end

  def test_issue
    payload = {
      issue: {
        "check_name" => "Style/LongLine",
        "description" => "Line is too long [1000/80]",
      },
      constant_name: "foo.rb",
      details_url: "http://example.com/repos/id/foo.rb#issue_123",
    }

    assert_lighthouse_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  def test_receive_test
    @stubs.post "projects/123/tickets.json" do |_env|
      [200, {}, '{"ticket":{"number": "123", "url":"http://foo.bar"}}']
    end

    response = receive_event(name: "test")

    assert_equal "Ticket <a href='http://foo.bar'>123</a> created.", response[:message]
  end

  private

  def assert_lighthouse_receives(event_data, title, ticket_body)
    @stubs.post "projects/123/tickets.json" do |env|
      body = JSON.parse(env[:body])
      assert_equal "token", env[:request_headers]["X-LighthouseToken"]
      assert_equal title, body["ticket"]["title"]
      assert_equal ticket_body, body["ticket"]["body"]
      [200, {}, '{"ticket":{"number": "123", "url":"http://lighthouse.com/projects/123/tickets/123.json"}}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Lighthouse,
      { subdomain: "foo", api_token: "token", project_id: "123" },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
