require File.expand_path('../helper', __FILE__)

class TestHipChat < CC::Service::TestCase
  def test_test_hook
    assert_hipchat_receives(
      "green",
      { name: "test", repo_name: "Rails" },
      "[Rails] This is a test of the HipChat service hook"
    )
  end

  def test_coverage_improved
    e = event(:coverage, to: 90.2, from: 80)

    assert_hipchat_receives("green", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has improved to 90.2% (+10.2%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_coverage_declined
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_hipchat_receives("red", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has declined to 88.6% (-6.0%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_quality_improved
    e = event(:quality, to: "A", from: "B")

    assert_hipchat_receives("green", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has improved from a B to an A",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_quality_declined_without_compare_url
    e = event(:quality, to: "D", from: "C")

    assert_hipchat_receives("red", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has declined from a C to a D",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_single_vulnerability
    e = event(:vulnerability, vulnerabilities: [
      { "warning_type" => "critical" }
    ])

    assert_hipchat_receives("red", e, [
      "[Example]",
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issue found",
    ].join(" "))
  end

  def test_single_vulnerability_with_location
    e = event(:vulnerability, vulnerabilities: [{
      "warning_type" => "critical",
      "location" => "app/user.rb line 120"
    }])

    assert_hipchat_receives("red", e, [
      "[Example]",
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

    assert_hipchat_receives("red", e, [
      "[Example]",
      "2 new <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issues found",
    ].join(" "))
  end

  def test_receive_test
    @stubs.post '/v1/rooms/message' do |env|
      [200, {}, '']
    end

    response = receive_event(name: "test")

    assert_equal "Test message sent", response[:message]
  end

  private

  def assert_hipchat_receives(color, event_data, expected_body)
    @stubs.post '/v1/rooms/message' do |env|
      body = JSON.parse(env[:body])
      assert_equal "token", body["auth_token"]
      assert_equal "123", body["room_id"]
      assert_equal true, body["notify"]
      assert_equal color, body["color"]
      assert_equal expected_body, body["message"]
      [200, {}, '']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::HipChat,
      { auth_token: "token", room_id: "123", notify: true },
      event_data || event(:quality, from: "C", to: "D")
    )
  end
end
