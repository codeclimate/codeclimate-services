require File.expand_path('../helper', __FILE__)

class TestSlack < CC::Service::TestCase
  def test_test_hook
    assert_slack_receives(
      :test,
      nil,
      { repo_name: "Rails" },
      "[Rails] This is a test of the Slack service hook"
    )
  end

  def test_coverage_improved
    e = event(:coverage, to: 90.2, from: 80)

    assert_slack_receives(:coverage, ":sunny:", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has improved to 90.2% (+10.2%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_coverage_declined
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_slack_receives(:coverage, ":umbrella:", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has declined to 88.6% (-6.0%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_quality_improved
    e = event(:quality, to: "A", from: "B")

    assert_slack_receives(:quality, ":sunny:", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|User>",
      "has improved from a B to an A",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_quality_declined_without_compare_url
    e = event(:quality, to: "D", from: "C")

    assert_slack_receives(:quality, ":umbrella:", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|User>",
      "has declined from a C to a D",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_single_vulnerability
    e = event(:vulnerability, vulnerabilities: [
      { "warning_type" => "critical" }
    ])

    assert_slack_receives(:vulnerability, nil, e, [
      "[Example]",
      "New <https://codeclimate.com/repos/1/feed|critical>",
      "issue found",
    ].join(" "))
  end

  def test_single_vulnerability_with_location
    e = event(:vulnerability, vulnerabilities: [{
      "warning_type" => "critical",
      "location" => "app/user.rb line 120"
    }])

    assert_slack_receives(:vulnerability, nil, e, [
      "[Example]",
      "New <https://codeclimate.com/repos/1/feed|critical>",
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

    assert_slack_receives(:vulnerability, nil, e, [
      "[Example]",
      "2 new <https://codeclimate.com/repos/1/feed|critical>",
      "issues found",
    ].join(" "))
  end

  private

  def assert_slack_receives(event_name, emoji, event_data, expected_body)
    @stubs.post '/token' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "Code Climate", body["username"]
      assert_equal emoji, body["icon_emoji"] # may be nil
      assert_equal expected_body, body["text"]
      [200, {}, '']
    end

    receive(
      CC::Service::Slack,
      event_name,
      { url: "http://api.slack.com/token", channel: "#general" },
      event_data
    )
  end
end