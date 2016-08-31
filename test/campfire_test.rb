require File.expand_path("../helper", __FILE__)

class TestCampfire < CC::Service::TestCase
  def test_config
    assert_raises CC::Service::ConfigurationError do
      service(CC::Service::Campfire, {}, name: "test")
    end
  end

  def test_test_hook
    assert_campfire_receives(
      { name: "test", repo_name: "Rails" },
      "[Code Climate][Rails] This is a test of the Campfire service hook",
    )
  end

  def test_coverage_improved
    e = event(:coverage, to: 90.2, from: 80)

    assert_campfire_receives(e, [
      "[Code Climate][Example] :sunny:",
      "Test coverage has improved to 90.2% (+10.2%).",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  def test_coverage_declined
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_campfire_receives(e, [
      "[Code Climate][Example] :umbrella:",
      "Test coverage has declined to 88.6% (-6.0%).",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  def test_quality_improved
    e = event(:quality, to: "A", from: "B")

    assert_campfire_receives(e, [
      "[Code Climate][Example] :sunny:",
      "User has improved from a B to an A.",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  def test_quality_declined
    e = event(:quality, to: "D", from: "C")

    assert_campfire_receives(e, [
      "[Code Climate][Example] :umbrella:",
      "User has declined from a C to a D.",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  def test_single_vulnerability
    e = event(:vulnerability, vulnerabilities: [
                { "warning_type" => "critical" },
              ])

    assert_campfire_receives(e, [
      "[Code Climate][Example]",
      "New critical issue found.",
      "Details: https://codeclimate.com/repos/1/feed",
    ].join(" "))
  end

  def test_single_vulnerability_with_location
    e = event(:vulnerability, vulnerabilities: [{
                "warning_type" => "critical",
                "location" => "app/user.rb line 120",
              }])

    assert_campfire_receives(e, [
      "[Code Climate][Example]",
      "New critical issue found",
      "in app/user.rb line 120.",
      "Details: https://codeclimate.com/repos/1/feed",
    ].join(" "))
  end

  def test_multiple_vulnerabilities
    e = event(:vulnerability, warning_type: "critical", vulnerabilities: [{
                "warning_type" => "unused",
                "location" => "unused",
              }, {
                "warning_type" => "unused",
                "location" => "unused",
              }])

    assert_campfire_receives(e, [
      "[Code Climate][Example]",
      "2 new critical issues found.",
      "Details: https://codeclimate.com/repos/1/feed",
    ].join(" "))
  end

  def test_receive_test
    @stubs.post request_url do |_env|
      [200, {}, ""]
    end

    response = receive_event(name: "test")

    assert_equal "Test message sent", response[:message]
  end

  private

  def speak_uri
    "https://#{subdomain}.campfirenow.com#{request_url}"
  end

  def request_url
    "/room/#{room}/speak.json"
  end

  def subdomain
    "sub"
  end

  def room
    "123"
  end

  def assert_campfire_receives(event_data, expected_body)
    @stubs.post request_url do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_body, body["message"]["body"]
      [200, {}, ""]
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Campfire,
      { token: "token", subdomain: subdomain, room_id: room },
      event_data || event(:quality, to: "D", from: "C"),
    )
  end
end
