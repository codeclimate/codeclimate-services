require File.expand_path('../helper', __FILE__)

class TestAsana < CC::Service::TestCase
  def test_quality
    assert_asana_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate - https://codeclimate.com/repos/1/feed"
    )
  end

  def test_vulnerability
    assert_asana_receives(
      event(:vulnerability, vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }]),
      "New critical issue found in app/user.rb line 120 - https://codeclimate.com/repos/1/feed"
    )
  end

  def test_issue
    payload = {
      issue: {
        "check_name" => "Style/LongLine",
        "description" => "Line is too long [1000/80]"
      },
      constant_name: "foo.rb",
      details_url: "http://example.com/repos/id/foo.rb#issue_123"
    }

    assert_asana_receives(
      event(:issue, payload),
      "Fix \"Style/LongLine\" issue in foo.rb",
      "Line is too long [1000/80]\n\nhttp://example.com/repos/id/foo.rb#issue_123"
    )
  end

  def test_successful_post
    @stubs.post '/api/1.0/tasks' do |env|
      [200, {}, '{"data":{"id":"2"}}']
    end

    response = receive_event

    assert_equal "2", response[:id]
    assert_equal "https://app.asana.com/0/1/2", response[:url]
  end

  def test_receive_test
    @stubs.post '/api/1.0/tasks' do |env|
      [200, {}, '{"data":{"id":"4"}}']
    end

    response = receive_event(name: "test")

    assert_equal "Ticket <a href='https://app.asana.com/0/1/4'>4</a> created.", response[:message]
  end

  private

  def assert_asana_receives(event_data, name, notes = nil)
    @stubs.post '/api/1.0/tasks' do |env|
      body = JSON.parse(env[:body])
      data = body["data"]

      assert_equal "1",             data["workspace"]
      assert_equal "2",             data["projects"].first
      assert_equal "jim@asana.com", data["assignee"]
      assert_equal name,            data["name"]
      assert_equal notes,           data["notes"]

      [200, {}, '{"data":{"id":4}}']
    end

    receive_event(event_data)
  end

  def receive_event(event_data = nil)
    receive(
      CC::Service::Asana,
      { api_key: "abc123", workspace_id: "1", project_id: "2", assignee: "jim@asana.com" },
      event_data || event(:quality, to: "D", from: "C")
    )
  end
end
