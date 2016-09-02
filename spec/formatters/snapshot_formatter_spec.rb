require "helper"

describe SnapshotFormatter do
  def described_class
    CC::Formatters::SnapshotFormatter::Base
  end

  it "quality alert with new constants" do
    f = described_class.new("new_constants" => [{ "to" => { "rating" => "D" } }], "changed_constants" => [])
    refute_nil f.alert_constants_payload
  end

  it "quality alert with decreased constants" do
    f = described_class.new("new_constants" => [],
                            "changed_constants" => [{ "to" => { "rating" => "D" }, "from" => { "rating" => "A" } }])
    refute_nil f.alert_constants_payload
  end

  it "quality improvements with better ratings" do
    f = described_class.new("new_constants" => [],
                            "changed_constants" => [{ "to" => { "rating" => "A" }, "from" => { "rating" => "D" } }])
    refute_nil f.improved_constants_payload
  end

  it "nothing set without changes" do
    f = described_class.new("new_constants" => [], "changed_constants" => [])
    f.alert_constants_payload.should == nil
    f.improved_constants_payload.should == nil
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

    refute_nil f.alert_constants_payload
    refute_nil f.improved_constants_payload
  end
end
