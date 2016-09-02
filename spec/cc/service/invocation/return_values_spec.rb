describe CC::Service::Invocation::WithReturnValues do
  it "success returns upstream result" do
    handler = CC::Service::Invocation::WithReturnValues.new(
      -> { :return_value },
      "error message",
    )

    expect(handler.call).to eq(:return_value)
  end

  it "empty results returns hash" do
    handler = CC::Service::Invocation::WithReturnValues.new(
      -> { nil },
      "error message",
    )

    expect({ ok: false, message: "error message" }).to eq(handler.call)
  end
end
