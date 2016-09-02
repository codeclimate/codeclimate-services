describe CC::Formatters::SnapshotFormatter do
  def described_class
    CC::Formatters::SnapshotFormatter::Base
  end

  it "quality alert with new constants" do
    f = described_class.new("new_constants" => [{ "to" => { "rating" => "D" } }], "changed_constants" => [])
    expect(f.alert_constants_payload).not_to be_nil
  end

  it "quality alert with decreased constants" do
    f = described_class.new("new_constants" => [],
                            "changed_constants" => [{ "to" => { "rating" => "D" }, "from" => { "rating" => "A" } }])
    expect(f.alert_constants_payload).not_to be_nil
  end

  it "quality improvements with better ratings" do
    f = described_class.new("new_constants" => [],
                            "changed_constants" => [{ "to" => { "rating" => "A" }, "from" => { "rating" => "D" } }])
    expect(f.improved_constants_payload).not_to be_nil
  end

  it "nothing set without changes" do
    f = described_class.new("new_constants" => [], "changed_constants" => [])
    expect(f.alert_constants_payload).to be_nil
    expect(f.improved_constants_payload).to be_nil
  end

  it "snapshot formatter test with relaxed constraints" do
    f = CC::Formatters::SnapshotFormatter::Sample.new(
      "new_constants" => [{ "name" => "foo", "to" => { "rating" => "A" } }, { "name" => "bar", "to" => { "rating" => "A" } }],
      "changed_constants" => [
        { "from" => { "rating" => "B" }, "to" => { "rating" => "C" } },
        { "from" => { "rating" => "D" }, "to" => { "rating" => "D" } },
        { "from" => { "rating" => "D" }, "to" => { "rating" => "D" } },
        { "from" => { "rating" => "A" }, "to" => { "rating" => "B" } },
        { "from" => { "rating" => "C" }, "to" => { "rating" => "B" } },
      ],
    )

    expect(f.alert_constants_payload).not_to be_nil
    expect(f.improved_constants_payload).not_to be_nil
  end
end
