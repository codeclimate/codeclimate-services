
describe Asana, type: :service do
  it "quality" do
    assert_asana_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate - https://codeclimate.com/repos/1/feed",
    )
  end

  it "vulnerability" do
    assert_asana_receives(
      event(:vulnerability, vulnerabilities: [{
              "warning_type" => "critical",
              "location" => "app/user.rb line 120",
            }]),
      "New critical issue found in app/user.rb line 120 - https://codeclimate.com/repos/1/feed",
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

    assert_asana_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  it "successful post" do
    @stubs.post "/api/1.0/tasks" do |_env|
      [200, {}, '{"data":{"id":"2"}}']
    end

    response = receive_event

    response[:id].should == "2"
    response[:url].should == "https://app.asana.com/0/1/2"
  end

  it "receive test" do
    @stubs.post "/api/1.0/tasks" do |_env|
      [200, {}, '{"data":{"id":"4"}}']
    end

    response = receive_event(name: "test")

    response[:message].should == "Ticket <a href='https://app.asana.com/0/1/4'>4</a> created."
  end

  private

  def assert_asana_receives(event_data, name, notes = "")
    @stubs.post "/api/1.0/tasks" do |env|
      body = JSON.parse(env[:body])
      data = body["data"]

      data["workspace"].should == "1"
      data["projects"].first.should == "2"
      data["assignee"].should == "jim@asana.com"
      data["name"].should == name
      data["notes"].should == notes

      [200, {}, '{"data":{"id":4}}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Asana,
      { api_key: "abc123", workspace_id: "1", project_id: "2", assignee: "jim@asana.com" },
      event_data || event(:quality, to: "D", from: "C"),
    )
  end
end
