describe CC::Service::HipChat, type: :service do
  it "test hook" do
    assert_hipchat_receives(
      "green",
      { name: "test", repo_name: "Rails" },
      "[Rails] This is a test of the HipChat service hook",
    )
  end

  it "coverage improved" do
    e = event(:coverage, to: 90.2, from: 80)

    assert_hipchat_receives("green", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has improved to 90.2% (+10.2%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "coverage declined" do
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_hipchat_receives("red", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has declined to 88.6% (-6.0%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "quality improved" do
    e = event(:quality, to: "A", from: "B")

    assert_hipchat_receives("green", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has improved from a B to an A",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "quality declined without compare url" do
    e = event(:quality, to: "D", from: "C")

    assert_hipchat_receives("red", e, [
      "[Example]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has declined from a C to a D",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "single vulnerability" do
    e = event(:vulnerability, vulnerabilities: [
                { "warning_type" => "critical" },
              ])

    assert_hipchat_receives("red", e, [
      "[Example]",
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issue found",
    ].join(" "))
  end

  it "single vulnerability with location" do
    e = event(:vulnerability, vulnerabilities: [{
                "warning_type" => "critical",
                "location" => "app/user.rb line 120",
              }])

    assert_hipchat_receives("red", e, [
      "[Example]",
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
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

    assert_hipchat_receives("red", e, [
      "[Example]",
      "2 new <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issues found",
    ].join(" "))
  end

  it "receive test" do
    http_stubs.post "/v1/rooms/message" do |_env|
      [200, {}, ""]
    end

    response = receive_event(name: "test")

    expect(response[:message]).to eq("Test message sent")
  end

  private

  def assert_hipchat_receives(color, event_data, expected_body)
    http_stubs.post "/v1/rooms/message" do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      expect(body["auth_token"]).to eq("token")
      expect(body["room_id"]).to eq("123")
      expect(body["notify"]).to eq("true")
      expect(body["color"]).to eq(color)
      expect(body["message"]).to eq(expected_body)
      [200, {}, ""]
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    service_receive(
      CC::Service::HipChat,
      { auth_token: "token", room_id: "123", notify: true },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
