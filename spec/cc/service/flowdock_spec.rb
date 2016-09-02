describe CC::Service::Flowdock, type: :service do
  it "valid project parameter" do
    http_stubs.post "/v1/messages/team_inbox/token" do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      expect(body["project"]).to eq("Exampleorg")
      [200, {}, ""]
    end

    service_receive(
      CC::Service::Flowdock,
      { api_token: "token" },
      name: "test", repo_name: "Example.org",
    )
  end

  it "test hook" do
    assert_flowdock_receives(
      "Test",
      { name: "test", repo_name: "Example" },
      "This is a test of the Flowdock service hook",
    )
  end

  it "coverage improved" do
    e = event(:coverage, to: 90.2, from: 80)

    assert_flowdock_receives("Coverage", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has improved to 90.2% (+10.2%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "coverage declined" do
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_flowdock_receives("Coverage", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has declined to 88.6% (-6.0%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "quality improved" do
    e = event(:quality, to: "A", from: "B")

    assert_flowdock_receives("Quality", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has improved from a B to an A",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "quality declined" do
    e = event(:quality, to: "D", from: "C")

    assert_flowdock_receives("Quality", e, [
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has declined from a C to a D",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)",
    ].join(" "))
  end

  it "single vulnerability" do
    e = event(:vulnerability, vulnerabilities: [
                { "warning_type" => "critical" },
              ])

    assert_flowdock_receives("Vulnerability", e, [
      "New <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issue found",
    ].join(" "))
  end

  it "single vulnerability with location" do
    e = event(:vulnerability, vulnerabilities: [{
                "warning_type" => "critical",
                "location" => "app/user.rb line 120",
              }])

    assert_flowdock_receives("Vulnerability", e, [
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

    assert_flowdock_receives("Vulnerability", e, [
      "2 new <a href=\"https://codeclimate.com/repos/1/feed\">critical</a>",
      "issues found",
    ].join(" "))
  end

  it "receive test" do
    http_stubs.post request_url do |_env|
      [200, {}, ""]
    end

    response = receive_event(name: "test", repo_name: "foo")

    expect(response[:message]).to eq("Test message sent")
  end

  private

  def endpoint_url
    "https://api.flowdock.com#{request_url}"
  end

  def request_url
    "/v1/messages/team_inbox/#{token}"
  end

  def token
    "token"
  end

  def assert_flowdock_receives(subject, event_data, expected_body)
    http_stubs.post request_url do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      expect(body["source"]).to eq("Code Climate")
      expect(body["from_address"]).to eq("hello@codeclimate.com")
      expect(body["from_name"]).to eq("Code Climate")
      expect(body["format"]).to eq("html")
      expect(body["subject"]).to eq(subject)
      expect(body["project"]).to eq("Example")
      expect(body["content"]).to eq(expected_body)
      expect(body["link"]).to eq("https://codeclimate.com")
      [200, {}, ""]
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    service_receive(CC::Service::Flowdock, { api_token: "token" }, event_data || event(:quality, from: "D", to: "C"))
  end
end
