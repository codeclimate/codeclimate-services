# Build a chain of invocation wrappers which eventually calls receive on
# the given service, then execute that chain.
#
# Order is important. Each call to #with, wraps the last.
#
# Usage:
#
#   CC::Service::Invocation.new(service) do |i|
#     i.with :retries, 3
#     i.with :metrics, $statsd
#     i.with :error_handling, Rails.logger
#   end
#
# In the above example, service.receive could happen 4 times (once, then
# three retries) before an exception is re-raised up to the metrics
# collector, then up again to the error handling. If the order were
# reversed, the error handling middleware would prevent the other
# middleware from seeing any exceptions at all.
#
class CC::Service::Invocation
  class InvocationChain
    def initialize(&block)
      @invocation = block
    end

    def wrap(klass, *args)
      @invocation = klass.new(@invocation, *args)
    end

    def call
      @invocation.call
    end
  end

  class WithRetries
    def initialize(invocation, retries)
      @invocation = invocation
      @retries = retries
    end

    def call
      @invocation.call
    rescue => ex
      raise ex if @retries.zero?

      @retries -= 1
      retry
    end
  end

  class WithMetrics
    def initialize(invocation, statsd, prefix = nil)
      @invocation = invocation
      @statsd = statsd
      @prefix = prefix
    end

    def call
      @invocation.call
      @statsd.increment(success_key)
    rescue => ex
      @statsd.increment(error_key(ex))
      raise ex
    end

    def success_key
      ["services.invocations", @prefix].compact.join('.')
    end

    def error_key(ex)
      ["services.errors", @prefix, "#{ex.class.name.underscore}"].compact.join('.')
    end
  end

  class WithErrorHandling
    def initialize(invocation, logger, prefix = nil)
      @invocation = invocation
      @logger = logger
      @prefix = prefix
    end

    def call
      @invocation.call
    rescue => ex
      @logger.error(error_message(ex))
    end

    private

    def error_message(ex)
      message  = "Exception invoking service:"
      message << " [#{@prefix}]" if @prefix
      message << " (#{ex.class}) #{ex.message}"
    end
  end

  MIDDLEWARE = {
    retries: WithRetries,
    metrics: WithMetrics,
    error_handling: WithErrorHandling,
  }

  def initialize(service)
    @chain = InvocationChain.new { service.receive }

    yield(self) if block_given?

    @chain.call
  end

  def with(middleware, *args)
    if klass = MIDDLEWARE[middleware]
      @chain.wrap(klass, *args)
    end
  end
end
