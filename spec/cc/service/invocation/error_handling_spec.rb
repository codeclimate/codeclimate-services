describe CC::Service::Invocation::WithErrorHandling do
  it "success returns upstream result" do
    handler = CC::Service::Invocation::WithErrorHandling.new(
      -> { :success },
      FakeLogger.new,
      "not important",
    )

    expect(handler.call).to eq(:success)
  end

  it "http errors return relevant data" do
    logger = FakeLogger.new
    env = {
      status: 401,
      params: "params",
      url: "url",
    }

    handler = CC::Service::Invocation::WithErrorHandling.new(
      -> { raise CC::Service::HTTPError.new("foo", env) },
      logger,
      "prefix",
    )

    result = handler.call
    expect(result[:ok]).to eq(false)
    expect(result[:status]).to eq(401)
    expect(result[:params]).to eq("params")
    expect(result[:endpoint_url]).to eq("url")
    expect(result[:message]).to eq("foo")
    expect(result[:log_message]).to eq("Exception invoking service: [prefix] (CC::Service::HTTPError) foo. Response: <nil>")
  end

  it "error returns a hash with explanations" do
    logger = FakeLogger.new

    handler = CC::Service::Invocation::WithErrorHandling.new(
      -> { raise ArgumentError, "lol" },
      logger,
      "prefix",
    )

    result = handler.call
    expect(result[:ok]).to eq(false)
    expect(result[:message]).to eq("lol")
    expect(result[:log_message]).to eq("Exception invoking service: [prefix] (ArgumentError) lol")
  end
end
