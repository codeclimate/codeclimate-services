require File.expand_path('../helper', __FILE__)

class TestSlack < CC::Service::TestCase
  def test_test_hook
    assert_slack_receives(
      nil,
      { name: "test", repo_name: "Rails" },
      "[Rails] This is a test of the Slack service hook"
    )
  end

  def test_coverage_improved
    e = event(:coverage, to: 90.2, from: 80)

    assert_slack_receives("#38ae6f", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has improved to 90.2% (+10.2%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_coverage_declined
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_slack_receives("#ed2f00", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has declined to 88.6% (-6.0%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)"
    ].join(" "))
  end

  def test_single_vulnerability
    e = event(:vulnerability, vulnerabilities: [
      { "warning_type" => "critical" }
    ])

    assert_slack_receives(nil, e, [
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

    assert_slack_receives(nil, e, [
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

    assert_slack_receives(nil, e, [
      "[Example]",
      "2 new <https://codeclimate.com/repos/1/feed|critical>",
      "issues found",
    ].join(" "))
  end

  private

  def assert_slack_receives(color, event_data, expected_body)
    @stubs.post '/token' do |env|
      body = JSON.parse(env[:body])
      attachment = body["attachments"].first
      field = attachment["fields"].first
      assert_equal color, attachment["color"] # may be nil
      assert_equal expected_body, attachment["fallback"]
      assert_equal expected_body, field["value"]
      [200, {}, '']
    end

    receive(
      CC::Service::Slack,
      { webhook_url: "http://api.slack.com/token", channel: "#general" },
      event_data
    )
  end
end
