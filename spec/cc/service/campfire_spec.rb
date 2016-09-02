describe CC::Service::Campfire, type: :service do
  it "config" do
    expect { service(CC::Service::Campfire, {}, name: "test") }.to raise_error(CC::Service::ConfigurationError)
  end

  it "test hook" do
    assert_campfire_receives(
      { name: "test", repo_name: "Rails" },
      "[Code Climate][Rails] This is a test of the Campfire service hook",
    )
  end

  it "coverage improved" do
    e = event(:coverage, to: 90.2, from: 80)

    assert_campfire_receives(e, [
      "[Code Climate][Example] :sunny:",
      "Test coverage has improved to 90.2% (+10.2%).",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  it "coverage declined" do
    e = event(:coverage, to: 88.6, from: 94.6)

    assert_campfire_receives(e, [
      "[Code Climate][Example] :umbrella:",
      "Test coverage has declined to 88.6% (-6.0%).",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  it "quality improved" do
    e = event(:quality, to: "A", from: "B")

    assert_campfire_receives(e, [
      "[Code Climate][Example] :sunny:",
      "User has improved from a B to an A.",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  it "quality declined" do
    e = event(:quality, to: "D", from: "C")

    assert_campfire_receives(e, [
      "[Code Climate][Example] :umbrella:",
      "User has declined from a C to a D.",
      "(https://codeclimate.com/repos/1/feed)",
    ].join(" "))
  end

  it "single vulnerability" do
    e = event(:vulnerability, vulnerabilities: [
                { "warning_type" => "critical" },
              ])

    assert_campfire_receives(e, [
      "[Code Climate][Example]",
      "New critical issue found.",
      "Details: https://codeclimate.com/repos/1/feed",
    ].join(" "))
  end

  it "single vulnerability with location" do
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

  it "multiple vulnerabilities" do
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

  it "receive test" do
    http_stubs.post request_url do |_env|
      [200, {}, ""]
    end

    response = receive_event(name: "test")

    expect(response[:message]).to eq("Test message sent")
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
    http_stubs.post request_url do |env|
      body = JSON.parse(env[:body])
      expect(body["message"]["body"]).to eq(expected_body)
      [200, {}, ""]
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    service_receive(
      CC::Service::Campfire,
      { token: "token", subdomain: subdomain, room_id: room },
      event_data || event(:quality, to: "D", from: "C"),
    )
  end
end
