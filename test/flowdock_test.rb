require File.expand_path('../helper', __FILE__)

class TestFlowdock < CC::Service::TestCase
  def test_valid_project_parameter
    @stubs.post '/v1/messages/team_inbox/token' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "Exampleorg", body["project"]
      [200, {}, '']
    end

    receive(
      CC::Service::Flowdock,
      { api_token: "token" },
      { name: "test", repo_name: "Example.org" }
    )
  end

  def test_test_hook
    assert_flowdock_receives(
      "Test",
      { name: "test", repo_name: "Example" },
      "This is a test of the Flowdock service hook"
    )
  end

  def test_coverage_improved
    e = event(:coverage, to: 90.2, from: 80)

    assert_flowdock_receives("Coverage", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has improved to 90.2% (+10.2%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_coverage_declined
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_flowdock_receives("Coverage", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has declined to 88.6% (-6.0%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_quality_improved
    e = event(:quality, to: "A", from: "B")

    assert_flowdock_receives("Quality", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has improved from a B to an A",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_quality_declined
    e = event(:quality, to: "D", from: "C")

    assert_flowdock_receives("Quality", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has declined from a C to a D",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_single_vulnerability
    e = event(:vulnerability, vulnerabilities: [
      { "warning_type" => "critical" }
    ])

    assert_flowdock_receives("Vulnerability", e, [
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issue found",
    ].join(" "))
  end

  def test_single_vulnerability_with_location
    e = event(:vulnerability, vulnerabilities: [{
      "warning_type" => "critical",
      "location" => "app/user.rb line 120"
    }])

    assert_flowdock_receives("Vulnerability", e, [
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issue found in app/user.rb line 120",
    ].join(" "))
  end

  def test_multiple_vulnerabilities
    e = event(:vulnerability, warning_type: "critical", vulnerabilities: [{
      "warning_type" => "unused",
      "location" => "unused"
    }, {
      "warning_type" => "unused",
      "location" => "unused"
    }])

    assert_flowdock_receives("Vulnerability", e, [
      "2 new <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issues found",
    ].join(" "))
  end

  private

  def assert_flowdock_receives(subject, event_data, expected_body)
    @stubs.post '/v1/messages/team_inbox/token' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "Code Climate", body["source"]
      assert_equal "hello@codeclimate.com", body["from_address"]
      assert_equal "Code Climate", body["from_name"]
      assert_equal "html", body["format"]
      assert_equal subject, body["subject"]
      assert_equal "Example", body["project"]
      assert_equal expected_body, body["content"]
      assert_equal "https://codeclimate.com", body["link"]
      [200, {}, '']
    end

    receive(CC::Service::Flowdock, { api_token: "token" }, event_data)
  end
end
