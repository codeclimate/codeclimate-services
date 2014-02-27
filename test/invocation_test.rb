require File.expand_path('../helper', __FILE__)

class TestInvocation < Test::Unit::TestCase
  def test_success
    service = FakeService.new

    CC::Service::Invocation.new(service).invoke

    assert_equal 1, service.receive_count
  end

  def test_failure
    service = FakeService.new
    service.raise_on_receive = true

    CC::Service::Invocation.new(service).invoke

    # First call + N retries
    expected_count = 1 + CC::Service::Invocation::RETRIES
    assert_equal expected_count, service.receive_count
  end

  def test_success_metrics
    statsd = FakeStatsd.new
    logger = FakeLogger.new
    service = FakeService.new

    CC::Service::Invocation.new(service, statsd, logger).invoke

    assert_equal 1, statsd.incremented_keys.length
    assert_match /services\.invocations/, statsd.incremented_keys.first
    assert_empty logger.logged_errors
  end

  def test_failure_metrics
    statsd = FakeStatsd.new
    logger = FakeLogger.new
    service = FakeService.new
    service.raise_on_receive = true

    CC::Service::Invocation.new(service, statsd, logger).invoke

    refute_empty statsd.incremented_keys
    refute_empty logger.logged_errors
    assert_match /services\.errors/, statsd.incremented_keys.first
  end

  private

  class FakeService
    attr_reader :slug, :receive_count
    attr_accessor :raise_on_receive

    def initialize
      @slug = "fake-service"
      @receive_count = 0
    end

    def receive
      @receive_count += 1

      if @raise_on_receive
        raise "Boom"
      end
    end
  end

  class FakeStatsd
    attr_reader :incremented_keys

    def initialize
      @incremented_keys = Set.new
    end

    def increment(key)
      @incremented_keys << key
    end
  end

  class FakeLogger
    attr_reader :logged_errors

    def initialize
      @logged_errors = []
    end

    def error(message)
      @logged_errors << message
    end
  end
end
