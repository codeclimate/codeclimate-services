# encoding: UTF-8

require File.expand_path('../helper', __FILE__)

class WithMetrics < CC::Service::TestCase

  class FakeInvocation
    def call
      raise CC::Service::HTTPError.new("Whoa", {})
    end
  end

  def test_statsd_error_key
    statsd = Object.new
    statsd.stubs(:timing)
    statsd.expects("increment").with("services.errors.githubpullrequests.cc-service-http_error")
    CC::Service::Invocation::WithMetrics.new(FakeInvocation.new, statsd, "githubpullrequests").call rescue CC::Service::HTTPError
  end
end
