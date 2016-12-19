describe CC::Service::Asana, type: :service do
  it "requires an authorization key or token, and nudges users toward personal_access_token" do
    config = CC::Service::Asana::Config.new(workspace_id: '1234')
    expect(config).to_not be_valid
    expect(config.errors[:personal_access_token]).to eq ["can't be blank"]

    config.api_key = "foo"
    expect(config).to be_valid

    config.api_key = nil
    config.personal_access_token = "bar"
    expect(config).to be_valid
  end

  shared_examples "Asana integration" do |authorization|
    it "creates a ticket for quality changes" do
      assert_asana_receives(
        event(:quality, to: "D", from: "C"),
        "Refactor User from a D on Code Climate - https://codeclimate.com/repos/1/feed",
        authorization,
      )
    end

    it "creates a ticket for vulnerability changes" do
      assert_asana_receives(
        event(:vulnerability, vulnerabilities: [{
          "warning_type" => "critical",
          "location" => "app/user.rb line 120",
        }]),
        "New critical issue found in app/user.rb line 120 - https://codeclimate.com/repos/1/feed",
        authorization,
      )
    end

    it "creates a ticket for a new issue" do
      payload = {
        issue: {
          "check_name" => "Style/LongLine",
          "description" => "Line is too long [1000/80]",
        },
        constant_name: "foo.rb",
        details_url: "http://example.com/repos/id/foo.rb#issue_123",
      }

      assert_asana_receives(
        event(:issue, payload),
        "Fix \"Style/LongLine\" issue in foo.rb",
        authorization,
        "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
      )
    end

    it "can make a successful POST request" do
      http_stubs.post "/api/1.0/tasks" do |_env|
        [200, {}, '{"data":{"id":"2"}}']
      end

      response = receive_event(authorization)

      expect(response[:id]).to eq("2")
      expect(response[:url]).to eq("https://app.asana.com/0/1/2")
    end

    it "can make a test request" do
      http_stubs.post "/api/1.0/tasks" do |_env|
        [200, {}, '{"data":{"id":"4"}}']
      end

      response = receive_event(authorization, name: "test")

      expect(response[:message]).to eq("Ticket <a href='https://app.asana.com/0/1/4'>4</a> created.")
    end
  end

  it_behaves_like "Asana integration", :api_key
  it_behaves_like "Asana integration", :personal_access_token
  it_behaves_like "Asana integration", :both

  private

  def assert_asana_receives(event_data, name, authorization, notes = "")
    http_stubs.post "/api/1.0/tasks" do |env|
      case authorization
      when :api_key
        expect(env[:request_headers]["Authorization"]).to include("Basic")
      when :personal_access_token
        expect(env[:request_headers]["Authorization"]).to eq("Bearer def456")
      when :both
        # prefer the personal access token
        expect(env[:request_headers]["Authorization"]).to eq("Bearer def456")
      else
        raise ArgumentError
      end
      body = JSON.parse(env[:body])
      data = body["data"]

      expect(data["workspace"]).to eq("1")
      expect(data["projects"].first).to eq("2")
      expect(data["assignee"]).to eq("jim@asana.com")
      expect(data["name"]).to eq(name)
      expect(data["notes"]).to eq(notes)

      [200, {}, '{"data":{"id":4}}']
    end

    receive_event(authorization, event_data)
  end

  def receive_event(authorization, event_data = nil)
    service_configuration = { workspace_id: "1", project_id: "2", assignee: "jim@asana.com" }
    case authorization
    when :api_key
      service_configuration[:api_key] = "abc123"
    when :personal_access_token
      service_configuration[:personal_access_token] = "def456"
    when :both
      service_configuration[:api_key] = "abc123"
      service_configuration[:personal_access_token] = "def456"
    else raise ArgumentError
    end
    service_receive(
      CC::Service::Asana,
      service_configuration,
      event_data || event(:quality, to: "D", from: "C"),
    )
  end
end
