# encoding: UTF-8

require File.expand_path('../helper', __FILE__)

class TestSlack < CC::Service::TestCase
  def test_test_hook
    assert_slack_receives(
      nil,
      { name: "test", repo_name: "rails" },
      "[rails] This is a test of the Slack service hook"
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

  def test_quality_alert_with_new_constants
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{"name" => "Foo", "to" => {"rating" => "D"}}, {"name" => "bar.js", "to" => {"rating" => "F"}}],
             "changed_constants" => [],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z" }

    assert_slack_receives(CC::Service::Slack::RED_HEX, data,
"""Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ was just created and is an *F*""")
  end

  def test_quality_alert_with_new_constants_and_declined_constants
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{"name" => "Foo", "to" => {"rating" => "D"}}],
             "changed_constants" => [{"name" => "bar.js", "from" => {"rating" => "A"}, "to" => {"rating" => "F"}}],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z" }

    assert_slack_receives(CC::Service::Slack::RED_HEX, data,
"""Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ just declined from an *A* to an *F*""")
  end

  def test_quality_alert_with_new_constants_and_declined_constants_overflown
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{"name" => "Foo", "to" => {"rating" => "D"}}],
             "changed_constants" => [
               {"name" => "bar.js", "from" => {"rating" => "A"}, "to" => {"rating" => "F"}},
               {"name" => "baz.js", "from" => {"rating" => "B"}, "to" => {"rating" => "D"}},
               {"name" => "Qux",    "from" => {"rating" => "A"}, "to" => {"rating" => "D"}}
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed"
    }


    assert_slack_receives(CC::Service::Slack::RED_HEX, data,
"""Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ just declined from an *A* to an *F*
• _baz.js_ just declined from a *B* to a *D*

And <https://codeclimate.com/repos/1/feed|1 other change>""")
  end

  def test_quality_improvements
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [],
             "changed_constants" => [
               {"name" => "bar.js", "from" => {"rating" => "F"}, "to" => {"rating" => "A"}},
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed"
    }


    assert_slack_receives(CC::Service::Slack::GREEN_HEX, data,
"""Quality improvements in *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _bar.js_ just improved from an *F* to an *A*""")
  end

  def test_quality_improvements_overflown
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [],
             "changed_constants" => [
               {"name" => "Foo",    "from" => {"rating" => "F"}, "to" => {"rating" => "A"}},
               {"name" => "bar.js", "from" => {"rating" => "D"}, "to" => {"rating" => "B"}},
               {"name" => "baz.js", "from" => {"rating" => "D"}, "to" => {"rating" => "A"}},
               {"name" => "Qux",    "from" => {"rating" => "F"}, "to" => {"rating" => "A"}},
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed"
    }


    assert_slack_receives(CC::Service::Slack::GREEN_HEX, data,
"""Quality improvements in *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ just improved from an *F* to an *A*
• _bar.js_ just improved from a *D* to a *B*
• _baz.js_ just improved from a *D* to an *A*

And <https://codeclimate.com/repos/1/feed|1 other improvement>""")
  end

  def test_received_success
    response = assert_slack_receives(
      nil,
      { name: "test", repo_name: "rails" },
      "[rails] This is a test of the Slack service hook"
    )
    assert_true response[:ok]
    assert_equal "Test message sent", response[:message]
  end

  def test_receive_test
    @stubs.post '/token' do |env|
      [200, {}, 'ok']
    end

    response = receive_event(name: "test")

    assert_equal "Test message sent", response[:message]
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
      [200, {}, 'ok']
    end
    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Slack,
      { webhook_url: "http://api.slack.com/token", channel: "#general" },
      event_data || event(:quality, from: "C", to: "D")
    )
  end
end
