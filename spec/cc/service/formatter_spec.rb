describe CC::Service::Formatter do

  class TestFormatter < described_class
    def format_test
      message = message_prefix
      message << "This is a test"
    end
  end

  FakeService = Struct.new(:receive)

  it "supports passing nil as prefix" do
    formatter = TestFormatter.new(
      FakeService.new(:some_result),
      prefix: nil,
      prefix_with_repo: false,
    )

    expect(formatter.format_test).to eq("This is a test")
  end
end
