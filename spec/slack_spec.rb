# encoding: UTF-8


describe Slack, type: :service do
  it "test hook" do
    assert_slack_receives(
      nil,
      { name: "test", repo_name: "rails" },
      "[rails] This is a test of the Slack service hook",
    )
  end

  it "coverage improved" do
    e = event(:coverage, to: 90.2, from: 80)

    assert_slack_receives("#38ae6f", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has improved to 90.2% (+10.2%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)",
    ].join(" "))
  end

  it "coverage declined" do
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_slack_receives("#ed2f00", e, [
      "[Example]",
      "<https://codeclimate.com/repos/1/feed|Test coverage>",
      "has declined to 88.6% (-6.0%)",
      "(<https://codeclimate.com/repos/1/compare|Compare>)",
    ].join(" "))
  end

  it "single vulnerability" do
    e = event(:vulnerability, vulnerabilities: [
                { "warning_type" => "critical" },
              ])

    assert_slack_receives(nil, e, [
      "[Example]",
      "New <https://codeclimate.com/repos/1/feed|critical>",
      "issue found",
    ].join(" "))
  end

  it "single vulnerability with location" do
    e = event(:vulnerability, vulnerabilities: [{
                "warning_type" => "critical",
                "location" => "app/user.rb line 120",
              }])

    assert_slack_receives(nil, e, [
      "[Example]",
      "New <https://codeclimate.com/repos/1/feed|critical>",
      "issue found in app/user.rb line 120",
    ].join(" "))
  end

  it "multiple vulnerabilities" do
    e = event(:vulnerability, warning_type: "critical", vulnerabilities: [{
                "warning_type" => "unused",
                "location" => "unused",
              }, {
                "warning_type" => "unused",
                "location" => "unused",
              }])

    assert_slack_receives(nil, e, [
      "[Example]",
      "2 new <https://codeclimate.com/repos/1/feed|critical>",
      "issues found",
    ].join(" "))
  end

  it "quality alert with new constants" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{ "name" => "Foo", "to" => { "rating" => "D" } }, { "name" => "bar.js", "to" => { "rating" => "F" } }],
             "changed_constants" => [],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z" }

    response = assert_slack_receives(CC::Service::Slack::RED_HEX, data,
      """Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ was just created and is an *F*""")

    response[:ok].should.not == nil
  end

  it "quality alert with new constants and declined constants" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{ "name" => "Foo", "to" => { "rating" => "D" } }],
             "changed_constants" => [{ "name" => "bar.js", "from" => { "rating" => "A" }, "to" => { "rating" => "F" } }],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z" }

    assert_slack_receives(CC::Service::Slack::RED_HEX, data,
      """Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ just declined from an *A* to an *F*""")
  end

  it "quality alert with new constants and declined constants overflown" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [{ "name" => "Foo", "to" => { "rating" => "D" } }],
             "changed_constants" => [
               { "name" => "bar.js", "from" => { "rating" => "A" }, "to" => { "rating" => "F" } },
               { "name" => "baz.js", "from" => { "rating" => "B" }, "to" => { "rating" => "D" } },
               { "name" => "Qux", "from" => { "rating" => "A" }, "to" => { "rating" => "D" } },
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed" }

    assert_slack_receives(CC::Service::Slack::RED_HEX, data,
      """Quality alert triggered for *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ was just created and is a *D*
• _bar.js_ just declined from an *A* to an *F*
• _baz.js_ just declined from a *B* to a *D*

And <https://codeclimate.com/repos/1/feed|1 other change>""")
  end

  it "quality improvements" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [],
             "changed_constants" => [
               { "name" => "bar.js", "from" => { "rating" => "F" }, "to" => { "rating" => "A" } },
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed" }

    assert_slack_receives(CC::Service::Slack::GREEN_HEX, data,
      """Quality improvements in *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _bar.js_ just improved from an *F* to an *A*""")
  end

  it "quality improvements overflown" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [],
             "changed_constants" => [
               { "name" => "Foo", "from" => { "rating" => "F" }, "to" => { "rating" => "A" } },
               { "name" => "bar.js", "from" => { "rating" => "D" }, "to" => { "rating" => "B" } },
               { "name" => "baz.js", "from" => { "rating" => "D" }, "to" => { "rating" => "A" } },
               { "name" => "Qux", "from" => { "rating" => "F" }, "to" => { "rating" => "A" } },
             ],
             "compare_url" => "https://codeclimate.com/repos/1/compare/a...z",
             "details_url" => "https://codeclimate.com/repos/1/feed" }

    assert_slack_receives(CC::Service::Slack::GREEN_HEX, data,
      """Quality improvements in *Rails* (<https://codeclimate.com/repos/1/compare/a...z|Compare>)

• _Foo_ just improved from an *F* to an *A*
• _bar.js_ just improved from a *D* to a *B*
• _baz.js_ just improved from a *D* to an *A*

And <https://codeclimate.com/repos/1/feed|1 other improvement>""")
  end

  it "received success" do
    response = assert_slack_receives(
      nil,
      { name: "test", repo_name: "rails" },
      "[rails] This is a test of the Slack service hook",
    )
    response[:ok].should == true
    response[:message].should == "Test message sent"
  end

  it "receive test" do
    @stubs.post "/token" do |_env|
      [200, {}, "ok"]
    end

    response = receive_event(name: "test")

    response[:message].should == "Test message sent"
  end

  it "no changes in snapshot" do
    data = { "name" => "snapshot", "repo_name" => "Rails",
             "new_constants" => [],
             "changed_constants" => [] }
    response = receive_event(data)

    response[:ok].should == false
    response[:ignored].should.not == nil
  end

  private

  def assert_slack_receives(color, event_data, expected_body)
    @stubs.post "/token" do |env|
      body = JSON.parse(env[:body])
      attachment = body["attachments"].first
      field = attachment["fields"].first
      attachment["color"] # may be nil.should == color
      attachment["fallback"].should == expected_body
      field["value"].should == expected_body
      [200, {}, "ok"]
    end
    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Slack,
      { webhook_url: "http://api.slack.com/token", channel: "#general" },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
