require File.expand_path('../helper', __FILE__)

class TestGitHubPullRequestsPresenter < CC::Service::TestCase
  def test_message_no_issue_counts_in_payload
    assert_equal(
      "Code Climate has analyzed this pull request.",
      CC::Service::GitHubPullRequests::Presenter.new({}).success_message
    )
  end

  def test_message_singular
    assert_equal(
      "Code Climate found 1 new issue and 1 fixed issue.",
      message_from_issue_counts("fixed" => 1, "new" => 1)
    )
  end

  def test_message_plural
    assert_equal(
      "Code Climate found 2 new issues and 1 fixed issue.",
      message_from_issue_counts("fixed" => 1, "new" => 2)
    )
  end

  def test_message_only_fixed
    assert_equal(
      "Code Climate found 1 fixed issue.",
      message_from_issue_counts("fixed" => 1, "new" => 0)
    )
  end

  def test_message_only_new
    assert_equal(
      "Code Climate found 3 new issues.",
      message_from_issue_counts("fixed" => 0, "new" => 3)
    )
  end

  def test_message_no_new_or_fixed
    assert_equal(
      "Code Climate didn't find any new or fixed issues.",
      message_from_issue_counts("fixed" => 0, "new" => 0)
    )
  end

private

  def message_from_issue_counts(issue_counts)
    payload = { "issue_comparison_counts" => issue_counts }
    CC::Service::GitHubPullRequests::Presenter.new(payload).success_message
  end
end
