require File.expand_path('../helper', __FILE__)

class TestTrello < CC::Service::TestCase
  def test_unit
    @stubs.get '/1/boards/123/lists?key=key&token=tok' do |env|
      [200, {}, '{}']
    end

    @stubs.post '/1/cards' do |env|
      [200, {}, '{}']
    end

    receive(CC::Service::Trello, :unit,
      {
        application_key:  "key",
        member_token:     "tok",
        board_id:         "123",
        list_name:        "Todo"
      },
      { name: "User" })
  end
end
