require "helper"

class TestSnapshotFormatter < Test::Unit::TestCase
  def described_class
    CC::Formatters::SnapshotFormatter::Base
  end

  def test_quality_alert_with_new_constants
    f = described_class.new({"new_constants" => [{"to" => {"rating" => "D"}}], "changed_constants" => []})
    refute_nil f.alert_constants_payload
  end

  def test_quality_alert_with_decreased_constants
    f = described_class.new({"new_constants" => [],
                             "changed_constants" => [{"to" => {"rating" => "D"}, "from" => {"rating" => "A"}}]
    })
    refute_nil f.alert_constants_payload
  end

  def test_quality_improvements_with_better_ratings
    f = described_class.new({"new_constants" => [],
                             "changed_constants" => [{"to" => {"rating" => "A"}, "from" => {"rating" => "D"}}]
    })
    refute_nil f.improved_constants_payload
  end

  def test_nothing_set_without_changes
    f = described_class.new({"new_constants" => [], "changed_constants" => []})
    assert_nil f.alert_constants_payload
    assert_nil f.improved_constants_payload
  end

  def test_snapshot_formatter_test_with_relaxed_constraints
    f = CC::Formatters::SnapshotFormatter::Sample.new({
       "new_constants" => [{"name" => "foo", "to" => {"rating" => "A"}}, {"name" => "bar", "to" => {"rating" => "A"}}],
       "changed_constants" => [
         {"from" => {"rating" => "B"}, "to" => {"rating" => "C"}},
         {"from" => {"rating" => "D"}, "to" => {"rating" => "D"}},
         {"from" => {"rating" => "D"}, "to" => {"rating" => "D"}},
         {"from" => {"rating" => "A"}, "to" => {"rating" => "B"}},
         {"from" => {"rating" => "C"}, "to" => {"rating" => "B"}}
       ]})

    refute_nil f.alert_constants_payload
    refute_nil f.improved_constants_payload
  end

  def test_changed_when_snapshot_changed
    f = described_class.new({"new_constants" => [],
                             "changed_constants" => [{"to" => {"rating" => "A"}, "from" => {"rating" => "D"}}]
    })
    assert f.changed?
  end

  def test_changed_when_no_changes
    f = described_class.new({"new_constants" => [], "changed_constants" => []})
    refute f.changed?
  end
end
