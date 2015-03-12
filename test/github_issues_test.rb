require File.expand_path('../helper', __FILE__)

class TestGitHubIssues < CC::Service::TestCase
  def test_creation_success
    id = 1234
    number = 123
    url = "https://github.com/#{project}/pulls/#{number}"
    stub_http(request_url, [201, {}, %<{"id": #{id}, "number": #{number}, "html_url":"#{url}"}>])

    response = receive_event

    assert_equal id, response[:id]
    assert_equal number, response[:number]
    assert_equal url, response[:url]
  end

  def test_quality
    assert_github_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
  end

  def test_vulnerability
    assert_github_receives(
      event(:vulnerability, vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed"
    )
  end

  def test_receive_test
    @stubs.post request_url do |env|
      [200, {}, '{"number": 2, "html_url": "http://foo.bar"}']
    end

    response = receive_event(name: "test")

    assert_equal "Issue <a href='http://foo.bar'>#2</a> created.", response[:message]
  end

  private

  def project
    "brynary/test_repo"
  end

  def oauth_token
    "123"
  end

  def request_url
    "repos/#{project}/issues"
  end

  def assert_github_receives(event_data, title, ticket_body)
    @stubs.post request_url do |env|
      body = JSON.parse(env[:body])
      assert_equal "token #{oauth_token}", env[:request_headers]["Authorization"]
      assert_equal title, body["title"]
      assert_equal ticket_body, body["body"]
      [200, {}, '{}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::GitHubIssues,
      { oauth_token: "123", project: project },
      event_data || event(:quality, from: "D", to: "C")
    )
  end
end
