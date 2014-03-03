require File.expand_path('../helper', __FILE__)

class TestService < Test::Unit::TestCase
  def test_validates_events
    assert_raises(ArgumentError) do
      CC::Service.new(:foo, {}, {})
    end
  end

  def test_receive
    ret = CC::Service.receive(
      { statsd: "statsd", logger: "logger" },
      { name: :test, foo: "bar" },
      FakeInvocation
    )

    assert ret[:invoked]
    assert ret[:service].is_a?(CC::Service)
    assert_equal "test", ret[:service].event
    assert_equal "bar", ret[:service].payload["foo"]
    assert_equal "statsd", ret[:statsd]
    assert_equal "logger", ret[:logger]
  end

  FakeInvocation = Struct.new(:service, :statsd, :logger) do
    def invoke
      {
        invoked: true,
        service: service,
        statsd: statsd,
        logger: logger
      }
    end
  end
end
