require File.expand_path('../helper', __FILE__)

class InvocationErrorHandling < CC::Service::TestCase
  def test_success_returns_upstream_result
    handler = CC::Service::Invocation::WithErrorHandling.new(
      lambda { :success },
      FakeLogger.new,
      "not important"
    )

    assert_equal :success, handler.call
  end

  def test_http_errors_return_relevant_data
    logger = FakeLogger.new
    env = {
      status: 401,
      params: "params",
      url: "url"
    }

    handler = CC::Service::Invocation::WithErrorHandling.new(
      lambda { raise CC::Service::HTTPError.new("foo", env) },
      logger,
      "prefix"
    )

    result = handler.call
    assert_equal false, result[:ok]
    assert_equal 401, result[:status]
    assert_equal "params", result[:params]
    assert_equal "url", result[:endpoint_url]
    assert_equal "foo", result[:message]
    assert_equal "Exception invoking service: [prefix] (CC::Service::HTTPError) foo. Response: <nil>", result[:log_message]
  end

  def test_error_returns_a_hash_with_explanations
    logger = FakeLogger.new

    handler = CC::Service::Invocation::WithErrorHandling.new(
      lambda { raise ArgumentError.new("lol") },
      logger,
      "prefix"
    )

    result = handler.call
    assert_equal false, result[:ok]
    assert_equal "lol", result[:message]
    assert_equal "Exception invoking service: [prefix] (ArgumentError) lol", result[:log_message]
  end
end
