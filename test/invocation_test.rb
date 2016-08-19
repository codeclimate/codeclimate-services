require File.expand_path('../helper', __FILE__)

class TestInvocation < Test::Unit::TestCase
  def test_success
    service = FakeService.new(:some_result)

    result = CC::Service::Invocation.invoke(service)

    assert_equal 1, service.receive_count
    assert_equal :some_result, result
  end

  def test_success_with_return_values
    service = FakeService.new(:some_result)

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :return_values, "error"
    end

    assert_equal 1, service.receive_count
    assert_equal :some_result, result
  end

  def test_failure_with_return_values
    service = FakeService.new(nil)

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :return_values, "error"
    end

    assert_equal 1, service.receive_count
    assert_equal( {ok: false, message: "error"}, result )
  end

  def test_retries
    service = FakeService.new
    service.fake_error = RuntimeError.new
    error_occurred = false

    begin
      CC::Service::Invocation.invoke(service) do |i|
        i.with :retries, 3
      end
    rescue
      error_occurred = true
    end

    assert error_occurred
    assert_equal 1 + 3, service.receive_count
  end

  def test_metrics
    statsd = FakeStatsd.new

    CC::Service::Invocation.invoke(FakeService.new) do |i|
      i.with :metrics, statsd, "a_prefix"
    end

    assert_equal 1, statsd.incremented_keys.length
    assert_equal "services.invocations.a_prefix", statsd.incremented_keys.first
  end

  def test_metrics_on_errors
    statsd = FakeStatsd.new
    service = FakeService.new
    service.fake_error = RuntimeError.new
    error_occurred = false

    begin
      CC::Service::Invocation.invoke(service) do |i|
        i.with :metrics, statsd, "a_prefix"
      end
    rescue
      error_occurred = true
    end

    assert error_occurred
    assert_equal 1, statsd.incremented_keys.length
    assert_match(/^services\.errors\.a_prefix/, statsd.incremented_keys.first)
  end

  def test_user_message
    service = FakeService.new
    service.fake_error = CC::Service::HTTPError.new("Boom", {})
    service.override_user_message = "Hey do this"
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :error_handling, logger, "a_prefix"
    end

    assert_equal "Hey do this", result[:message]
    assert_match(/Boom/, result[:log_message])
  end

  def test_error_handling
    service = FakeService.new
    service.fake_error = RuntimeError.new("Boom")
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :error_handling, logger, "a_prefix"
    end

    assert_equal({ok: false, message: "Boom", log_message: "Exception invoking service: [a_prefix] (RuntimeError) Boom"}, result)
    assert_equal 1, logger.logged_errors.length
    assert_match(/^Exception invoking service: \[a_prefix\]/, logger.logged_errors.first)
  end

  def test_multiple_middleware
    service = FakeService.new
    service.fake_error = RuntimeError.new("Boom")
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :retries, 3
      i.with :error_handling, logger
    end

    assert_equal({ok: false, message: "Boom", log_message: "Exception invoking service: (RuntimeError) Boom"}, result)
    assert_equal 1 + 3, service.receive_count
    assert_equal 1, logger.logged_errors.length
  end

  private

  class FakeService
    attr_reader :receive_count
    attr_accessor :fake_error, :override_user_message

    def initialize(result = nil)
      @result = result
      @receive_count = 0
    end

    def receive
      @receive_count += 1

      begin
        raise @fake_error if @fake_error
      rescue => e
        if override_user_message
          e.user_message = override_user_message
        end
        raise e
      end

      @result
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

    def timing(key, value)
    end
  end

end
