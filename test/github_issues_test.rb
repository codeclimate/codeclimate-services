require File.expand_path('../helper', __FILE__)

class TestGitHubIssues < CC::Service::TestCase
  def test_unit
    # @stubs.post '/repos/brynary/test_repo/issues' do |env|
    #   assert_equal "token token", env[:request_headers]["Authorization"]
    #   [200, {}, '{}']
    # end

    # receive(CC::Service::GitHubIssues, :unit,
    #   { oauth_token: "token" },
    #   { name: "User" })
  end
end
