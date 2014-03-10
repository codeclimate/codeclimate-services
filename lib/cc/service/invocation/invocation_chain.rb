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
end
