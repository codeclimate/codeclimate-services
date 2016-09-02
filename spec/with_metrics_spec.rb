# encoding: UTF-8


class WithMetrics < CC::Service::TestCase
  class FakeInvocation
    def call
      raise CC::Service::HTTPError.new("Whoa", {})
    end
  end

  it "statsd error key" do
    statsd = Object.new
    statsd.stubs(:timing)
    statsd.expects("increment").with("services.errors.githubpullrequests.cc-service-http_error")
    begin
      CC::Service::Invocation::WithMetrics.new(FakeInvocation.new, statsd, "githubpullrequests").call
    rescue
      CC::Service::HTTPError
    end
  end
end
