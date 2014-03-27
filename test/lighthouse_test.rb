require File.expand_path('../helper', __FILE__)

class TestLighthouse < CC::Service::TestCase
  def test_quality
    assert_lighthouse_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
  end

  def test_vulnerability
    assert_lighthouse_receives(
      event(:vulnerability, vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed"
    )
  end

  private

  def assert_lighthouse_receives(event_data, title, ticket_body)
    @stubs.post 'projects/123/tickets.json' do |env|
      body = JSON.parse(env[:body])
      assert_equal "token", env[:request_headers]["X-LighthouseToken"]
      assert_equal title, body["ticket"]["title"]
      assert_equal ticket_body, body["ticket"]["body"]
      [200, {}, '{"ticket":{}}']
    end

    receive(
      CC::Service::Lighthouse,
      { subdomain: "foo", api_token: "token", project_id: "123" },
      event_data
    )
  end
end
