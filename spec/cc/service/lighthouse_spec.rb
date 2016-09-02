describe CC::Service::Lighthouse, type: :service do
  it "quality" do
    response = assert_lighthouse_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
    expect(response[:id]).to eq("123")
    expect("http://lighthouse.com/projects/123/tickets/123.json").to eq(response[:url])
  end

  it "vulnerability" do
    assert_lighthouse_receives(
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

    assert_lighthouse_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  it "receive test" do
    http_stubs.post "projects/123/tickets.json" do |_env|
      [200, {}, '{"ticket":{"number": "123", "url":"http://foo.bar"}}']
    end

    response = receive_event(name: "test")

    expect(response[:message]).to eq("Ticket <a href='http://foo.bar'>123</a> created.")
  end

  private

  def assert_lighthouse_receives(event_data, title, ticket_body)
    http_stubs.post "projects/123/tickets.json" do |env|
      body = JSON.parse(env[:body])
      expect(env[:request_headers]["X-LighthouseToken"]).to eq("token")
      expect(body["ticket"]["title"]).to eq(title)
      expect(body["ticket"]["body"]).to eq(ticket_body)
      [200, {}, '{"ticket":{"number": "123", "url":"http://lighthouse.com/projects/123/tickets/123.json"}}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Lighthouse,
      { subdomain: "foo", api_token: "token", project_id: "123" },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
