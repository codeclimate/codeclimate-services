require File.expand_path('../helper', __FILE__)

class InvocationReturnValuesTest < CC::Service::TestCase
  def test_success_returns_upstream_result
    handler = CC::Service::Invocation::WithReturnValues.new(
      lambda { :return_value },
      "error message"
    )

    assert_equal :return_value, handler.call
  end

  def test_empty_results_returns_hash
    handler = CC::Service::Invocation::WithReturnValues.new(
      lambda { nil },
      "error message"
    )

    assert_equal( {ok: false, message: "error message"}, handler.call )
  end
end
