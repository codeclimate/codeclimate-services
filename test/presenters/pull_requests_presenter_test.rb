require "helper"
require "cc/presenters/pull_requests_presenter"

class TestPullRequestsPresenter < CC::Service::TestCase
  def test_message_singular
    assert_equal(
      "Code Climate found 1 new issue and 1 fixed issue.",
      build_presenter("fixed" => 1, "new" => 1).success_message
    )
  end

  def test_message_plural
    assert_equal(
      "Code Climate found 2 new issues and 1 fixed issue.",
      build_presenter("fixed" => 1, "new" => 2).success_message
    )
  end

  def test_message_only_fixed
    assert_equal(
      "Code Climate found 1 fixed issue.",
      build_presenter("fixed" => 1, "new" => 0).success_message
    )
  end

  def test_message_only_new
    assert_equal(
      "Code Climate found 3 new issues.",
      build_presenter("fixed" => 0, "new" => 3).success_message
    )
  end

  def test_message_no_new_or_fixed
    assert_equal(
      "Code Climate didn't find any new or fixed issues.",
      build_presenter("fixed" => 0, "new" => 0).success_message
    )
  end

  def test_message_coverage_same
    assert_equal(
      "85% test coverage",
      build_presenter({}, "covered_percent" => 85, "covered_percent_delta" => 0).coverage_message
    )
  end

  def test_message_coverage_up
    assert_equal(
      "85.5% test coverage (+2.46%)",
      build_presenter({}, "covered_percent" => 85.5, "covered_percent_delta" => 2.4567).coverage_message
    )
  end

  def test_message_coverage_down
    assert_equal(
      "85.35% test coverage (-3%)",
      build_presenter({}, "covered_percent" => 85.348, "covered_percent_delta" => -3.0).coverage_message
    )
  end

private

  def build_payload(issue_counts)
    { "issue_comparison_counts" => issue_counts }
  end

  def build_presenter(issue_counts, payload = {})
    CC::Service::PullRequestsPresenter.new(build_payload(issue_counts).merge(payload))
  end
end
