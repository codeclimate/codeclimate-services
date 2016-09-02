describe CC::Service::Invocation::WithMetrics, type: :service do
  class FakeInvocation
    def call
      raise CC::Service::HTTPError.new("Whoa", {})
    end
  end

  it "statsd error key" do
    statsd = double(:statsd)
    allow(statsd).to receive(:timing)
    expect(statsd).to receive(:increment).with("services.errors.githubpullrequests.cc-service-http_error")
    begin
      CC::Service::Invocation::WithMetrics.new(FakeInvocation.new, statsd, "githubpullrequests").call
    rescue CC::Service::HTTPError
      #noop
    end
  end
end
