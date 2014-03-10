require 'cc/service/invocation/invocation_chain'
require 'cc/service/invocation/with_retries'
require 'cc/service/invocation/with_metrics'
require 'cc/service/invocation/with_error_handling'

class CC::Service::Invocation
  MIDDLEWARE = {
    retries: WithRetries,
    metrics: WithMetrics,
    error_handling: WithErrorHandling,
  }

  # Build a chain of invocation wrappers which eventually calls receive
  # on the given service, then execute that chain.
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
  # In the above example, service.receive could happen 4 times (once,
  # then three retries) before an exception is re-raised up to the
  # metrics collector, then up again to the error handling. If the order
  # were reversed, the error handling middleware would prevent the other
  # middleware from seeing any exceptions at all.
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
