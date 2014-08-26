class CC::Service::Invocation
  class WithMetrics
    def initialize(invocation, statsd, prefix = nil)
      @invocation = invocation
      @statsd = statsd
      @prefix = prefix
    end

    def call
      start_time = Time.now

      result = @invocation.call
      @statsd.increment(success_key)

      result
    rescue => ex
      @statsd.increment(error_key(ex))
      raise ex
    ensure
      duration = ((Time.now - start_time) * 1_000).round
      @statsd.timing(timing_key, duration)
    end

    def success_key
      ["services.invocations", @prefix].compact.join('.')
    end

    def timing_key
      ["services.timing", @prefix].compact.join('.')
    end

    def error_key(ex)
      ["services.errors", @prefix, "#{ex.class.name.underscore}"].compact.join('.')
    end
  end
end
