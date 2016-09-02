describe CC::Service::Invocation do
  it "success" do
    service = FakeService.new(:some_result)

    result = CC::Service::Invocation.invoke(service)

    expect(service.receive_count).to eq(1)
    expect(result).to eq(:some_result)
  end

  it "success with return values" do
    service = FakeService.new(:some_result)

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :return_values, "error"
    end

    expect(service.receive_count).to eq(1)
    expect(result).to eq(:some_result)
  end

  it "failure with return values" do
    service = FakeService.new(nil)

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :return_values, "error"
    end

    expect(service.receive_count).to eq(1)
    expect({ ok: false, message: "error" }).to eq(result)
  end

  it "retries" do
    service = FakeService.new
    service.fake_error = RuntimeError.new
    error_occurred = false

    begin
      CC::Service::Invocation.invoke(service) do |i|
        i.with :retries, 3
      end
    rescue
      error_occurred = true
    end

    expect(error_occurred).not_to be_nil
    expect(service.receive_count).to eq(1 + 3)
  end

  it "metrics" do
    statsd = FakeStatsd.new

    CC::Service::Invocation.invoke(FakeService.new) do |i|
      i.with :metrics, statsd, "a_prefix"
    end

    expect(statsd.incremented_keys.length).to eq(1)
    expect(statsd.incremented_keys.first).to eq("services.invocations.a_prefix")
  end

  it "metrics on errors" do
    statsd = FakeStatsd.new
    service = FakeService.new
    service.fake_error = RuntimeError.new
    error_occurred = false

    begin
      CC::Service::Invocation.invoke(service) do |i|
        i.with :metrics, statsd, "a_prefix"
      end
    rescue
      error_occurred = true
    end

    expect(error_occurred).not_to be_nil
    expect(statsd.incremented_keys.length).to eq(1)
    expect(statsd.incremented_keys.first).to match(/^services\.errors\.a_prefix/)
  end

  it "user message" do
    service = FakeService.new
    service.fake_error = CC::Service::HTTPError.new("Boom", {})
    service.override_user_message = "Hey do this"
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :error_handling, logger, "a_prefix"
    end

    expect(result[:message]).to eq("Hey do this")
    expect(result[:log_message]).to match(/Boom/)
  end

  it "error handling" do
    service = FakeService.new
    service.fake_error = RuntimeError.new("Boom")
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :error_handling, logger, "a_prefix"
    end

    expect({ ok: false, message: "Boom", log_message: "Exception invoking service: [a_prefix] (RuntimeError) Boom" }).to eq(result)
    expect(logger.logged_errors.length).to eq(1)
    expect(logger.logged_errors.first).to match(/^Exception invoking service: \[a_prefix\]/)
  end

  it "multiple middleware" do
    service = FakeService.new
    service.fake_error = RuntimeError.new("Boom")
    logger = FakeLogger.new

    result = CC::Service::Invocation.invoke(service) do |i|
      i.with :retries, 3
      i.with :error_handling, logger
    end

    expect({ ok: false, message: "Boom", log_message: "Exception invoking service: (RuntimeError) Boom" }).to eq(result)
    expect(service.receive_count).to eq(1 + 3)
    expect(logger.logged_errors.length).to eq(1)
  end

  private

  class FakeService
    attr_reader :receive_count
    attr_accessor :fake_error, :override_user_message

    def initialize(result = nil)
      @result = result
      @receive_count = 0
    end

    def receive
      @receive_count += 1

      begin
        raise fake_error if fake_error
      rescue => e
        if override_user_message
          e.user_message = override_user_message
        end
        raise e
      end

      @result
    end
  end

  class FakeStatsd
    attr_reader :incremented_keys

    def initialize
      @incremented_keys = Set.new
    end

    def increment(key)
      @incremented_keys << key
    end

    def timing(key, value)
    end
  end
end
