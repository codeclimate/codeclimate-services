describe CC::Service::Invocation::WithReturnValues do
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

    expect({ ok: false, message: "error message" }).to eq(handler.call)
  end
end
