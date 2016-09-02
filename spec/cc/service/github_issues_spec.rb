describe CC::Service::GitHubIssues, type: :service do
  it "creation success" do
    id = 1234
    number = 123
    url = "https://github.com/#{project}/pulls/#{number}"
    stub_http(request_url, [201, {}, %({"id": #{id}, "number": #{number}, "html_url":"#{url}"})])

    response = receive_event

    expect(response[:id]).to eq(id)
    expect(response[:number]).to eq(number)
    expect(response[:url]).to eq(url)
  end

  it "quality" do
    assert_github_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
  end

  it "quality without rating" do
    assert_github_receives(
      event(:quality, to: nil),
      "Refactor User on Code Climate",
      "https://codeclimate.com/repos/1/feed",
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

    assert_github_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  it "vulnerability" do
    assert_github_receives(
      event(:vulnerability, vulnerabilities: [{
              "warning_type" => "critical",
              "location" => "app/user.rb line 120",
            }]),
      "New critical issue found in app/user.rb line 120",
      "A critical vulnerability was found by Code Climate in app/user.rb line 120.\n\nhttps://codeclimate.com/repos/1/feed",
    )
  end

  it "receive test" do
    http_stubs.post request_url do |_env|
      [200, {}, '{"number": 2, "html_url": "http://foo.bar"}']
    end

    response = receive_event(name: "test")

    expect(response[:message]).to eq("Issue <a href='http://foo.bar'>#2</a> created.")
  end

  it "different base url" do
    http_stubs.post request_url do |env|
      expect(env[:url].to_s).to eq("http://example.com/#{request_url}")
      [200, {}, '{"number": 2, "html_url": "http://foo.bar"}']
    end

    response = receive_event({ name: "test" }, base_url: "http://example.com")

    expect(response[:message]).to eq("Issue <a href='http://foo.bar'>#2</a> created.")
  end

  private

  def project
    "brynary/test_repo"
  end

  def oauth_token
    "123"
  end

  def request_url
    "repos/#{project}/issues"
  end

  def assert_github_receives(event_data, title, ticket_body)
    http_stubs.post request_url do |env|
      body = JSON.parse(env[:body])
      expect(env[:request_headers]["Authorization"]).to eq("token #{oauth_token}")
      expect(body["title"]).to eq(title)
      expect(body["body"]).to eq(ticket_body)
      [200, {}, "{}"]
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil, config = {})
    service_receive(
      CC::Service::GitHubIssues,
      { oauth_token: "123", project: project }.merge(config),
      event_data || event(:quality, from: "D", to: "C"),
    )
  end
end
