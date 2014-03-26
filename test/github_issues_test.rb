require File.expand_path('../helper', __FILE__)

class TestGitHubIssues < CC::Service::TestCase
  def test_quality
    assert_github_receives(
      event(:quality, to: "D", from: "C"),
      "Refactor User from a D on Code Climate",
      "https://codeclimate.com/repos/1/feed"
    )
  end

  private

  def assert_github_receives(event_data, title, ticket_body)
    @stubs.post 'repos/brynary/test_repo/issues' do |env|
      body = JSON.parse(env[:body])
      assert_equal "token 123", env[:request_headers]["Authorization"]
      assert_equal title, body["title"]
      assert_equal ticket_body, body["body"]
      [200, {}, '{}']
    end

    receive(
      CC::Service::GitHubIssues,
      { oauth_token: "123" },
      event_data
    )
  end
end
