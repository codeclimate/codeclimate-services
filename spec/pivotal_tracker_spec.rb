require File.expand_path("../helper", __FILE__)

class TestPivotalTracker < CC::Service::TestCase
  it "quality" do
    response = assert_pivotal_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed",
    )
    response[:id].should == "123"
    assert_equal "http://pivotaltracker.com/n/projects/123/stories/123",
      response[:url]
  end

  it "vulnerability" do
    assert_pivotal_receives(
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

    assert_pivotal_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123",
    )
  end

  it "receive test" do
    @stubs.post "services/v3/projects/123/stories" do |_env|
      [200, {}, "<story><id>123</id><url>http://foo.bar</url></story>"]
    end

    response = receive_event(name: "test")

    response[:message].should == "Ticket <a href='http://foo.bar'>123</a> created."
  end

  private

  def assert_pivotal_receives(event_data, name, description)
    @stubs.post "services/v3/projects/123/stories" do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      env[:request_headers]["X-TrackerToken"].should == "token"
      body["story[name]"].should == name
      body["story[description]"].should == description
      [200, {}, "<doc><story><id>123</id><url>http://pivotaltracker.com/n/projects/123/stories/123</url></story></doc>"]
    end
    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::PivotalTracker,
      { api_token: "token", project_id: "123" },
      event_data || event(:quality, from: "C", to: "D"),
    )
  end
end
