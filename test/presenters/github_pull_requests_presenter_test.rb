require "helper"
require "cc/presenters/github_pull_requests_presenter"

class TestGitHubPullRequestsPresenter < CC::Service::TestCase
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

private

  def build_payload(issue_counts)
    { "issue_comparison_counts" => issue_counts }
  end

  def build_presenter(issue_counts)
    CC::Service::GitHubPullRequestsPresenter.new(build_payload(issue_counts))
  end
end
