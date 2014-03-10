class CC::Service::Invocation
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
end
