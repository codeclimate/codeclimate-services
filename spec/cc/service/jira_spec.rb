describe CC::Service::Jira, type: :service do
  it "successful receive" do
    response = assert_jira_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
    expect(response[:id]).to eq("10000")
  end

  it "quality" do
    assert_jira_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
  end

  it "vulnerability" do
    assert_jira_receives(
      event(:vulnerability, vulnerabilities: [{
              "warning_type" => "critical",
              "location" => "app/user.rb line 120",
            }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed",
    )
  end

  it "issue" do
    payload = {
      issue: {
        "check_name" => "Style/LongLine",
        "description" => "Line is too long [1000/80]",
      },
      constant_name: "foo.rb",
      details_url: "http://example.com/repos/id/foo.rb#issue_123",
    }

    assert_jira_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  it "receive test" do
    http_stubs.post "/rest/api/2/issue/" do |_env|
      [200, {}, '{"id": 12345, "key": "CC-123", "self": "http://foo.bar"}']
    end

    response = receive_event(name: "test")

    expect(response[:message]).to eq("Ticket <a href='https://foo.com/browse/CC-123'>12345</a> created.")
  end

  private

  def assert_jira_receives(event_data, title, ticket_body)
    http_stubs.post "/rest/api/2/issue/" do |env|
      body = JSON.parse(env[:body])
      expect(env[:request_headers]["Authorization"]).to eq("Basic Zm9vOmJhcg==")
      expect(body["fields"]["summary"]).to eq(title)
      expect(body["fields"]["description"]).to eq(ticket_body)
      expect(body["fields"]["issuetype"]["name"]).to eq("Task")
      [200, {}, '{"id":"10000"}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    service_receive(
      CC::Service::Jira,
      { domain: "foo.com", username: "foo", password: "bar", project_id: "100" },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
