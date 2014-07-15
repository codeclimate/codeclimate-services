class CC::Service::Invocation
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

      nil
    end

    private

    def error_message(ex)
      if ex.respond_to?(:response_body)
        response_body = ". Response: <#{ex.response_body.inspect}>"
      else
        response_body = ""
      end

      message  = "Exception invoking service:"
      message << " [#{@prefix}]" if @prefix
      message << " (#{ex.class}) #{ex.message}"
      message << response_body
    end
  end
end
