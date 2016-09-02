describe "Invocation error handling" do
  it "success returns upstream result" do
    handler = CC::Service::Invocation::WithErrorHandling.new(
      -> { :success },
      FakeLogger.new,
      "not important",
    )

    handler.call.should == :success
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
    result[:ok].should == false
    result[:status].should == 401
    result[:params].should == "params"
    result[:endpoint_url].should == "url"
    result[:message].should == "foo"
    result[:log_message].should == "Exception invoking service: [prefix] (CC::Service::HTTPError) foo. Response: <nil>"
  end

  it "error returns a hash with explanations" do
    logger = FakeLogger.new

    handler = CC::Service::Invocation::WithErrorHandling.new(
      -> { raise ArgumentError, "lol" },
      logger,
      "prefix",
    )

    result = handler.call
    result[:ok].should == false
    result[:message].should == "lol"
    result[:log_message].should == "Exception invoking service: [prefix] (ArgumentError) lol"
  end
end
