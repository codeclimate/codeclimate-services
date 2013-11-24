require File.expand_path('../helper', __FILE__)

class TestFlowdock < CC::Service::TestCase
  def test_coverage_change
    @stubs.post '/v1/messages/team_inbox/token' do |env|
      [200, {}, '']
    end

    receive(CC::Service::Flowdock, :unit,
      { api_token: "token" },
      { name: "User" })
  end
end
