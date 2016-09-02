require File.expand_path("../helper", __FILE__)

class InvocationReturnValuesTest < CC::Service::TestCase
  it "success returns upstream result" do
    handler = CC::Service::Invocation::WithReturnValues.new(
      -> { :return_value },
      "error message",
    )

    handler.call.should == :return_value
  end

  it "empty results returns hash" do
    handler = CC::Service::Invocation::WithReturnValues.new(
      -> { nil },
      "error message",
    )

    assert_equal({ ok: false, message: "error message" }, handler.call)
  end
end
