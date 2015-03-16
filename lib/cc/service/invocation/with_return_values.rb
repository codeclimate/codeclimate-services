class CC::Service::Invocation
  class WithReturnValues
    def initialize(invocation, message = nil)
      @invocation = invocation
      @message = message || "An internal error happened"
    end

    def call
      result = @invocation.call
      if result.nil?
        { ok: false, message: @message }
      else
        result
      end
    end
  end
end

