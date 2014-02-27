require File.expand_path('../helper', __FILE__)

class TestLighthouse < CC::Service::TestCase
  def test_unit
    # @stubs.post '/projects/123/tickets.json' do |env|
    #   assert_equal "token", env[:request_headers]["X-LighthouseToken"]
    #   [200, {}, '{ "ticket": {} }']
    # end

    # receive(CC::Service::Lighthouse, :unit,
    #   { subdomain: "example", api_token: "token", project_id: "123" },
    #   { name: "User" })
  end
end
