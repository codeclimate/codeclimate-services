class CC::Service::Invocation
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
end
