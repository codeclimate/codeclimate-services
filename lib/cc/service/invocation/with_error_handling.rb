class CC::Service::Invocation
  class WithErrorHandling
    def initialize(invocation, logger, prefix = nil)
      @invocation = invocation
      @logger = logger
      @prefix = prefix
    end

    def call
      @invocation.call
    rescue CC::Service::HTTPError => e
      @logger.error(error_message(e))
      {
        ok: false,
        params: e.params,
        status: e.status,
        endpoint_url: e.endpoint_url,
        message: e.user_message || e.message,
        log_message: error_message(e),
      }
    rescue => e
      @logger.error(error_message(e))
      {
        ok: false,
        message: e.message,
        log_message: error_message(e),
      }
    end

    private

    def error_message(e)
      response_body =
        if e.respond_to?(:response_body)
          ". Response: <#{e.response_body.inspect}>"
        else
          ""
        end

      message = "Exception invoking service:"
      message << " [#{@prefix}]" if @prefix
      message << " (#{e.class}) #{e.message}"
      message << response_body
    end
  end
end
