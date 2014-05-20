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

      {
        error: {
          class: ex.class,
          message: ex.message
        }
      }
    end

    private

    def error_message(ex)
      message  = "Exception invoking service:"
      message << " [#{@prefix}]" if @prefix
      message << " (#{ex.class}) #{ex.message}"
    end
  end
end
