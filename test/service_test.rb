require File.expand_path('../helper', __FILE__)

class TestService < Test::Unit::TestCase
  def test_validates_events
    assert_raises(ArgumentError) do
      CC::Service.new(:foo, {}, {})
    end
  end
end
