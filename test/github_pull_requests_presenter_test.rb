require File.expand_path('../helper', __FILE__)

class TestGitHubPullRequestsPresenter < CC::Service::TestCase
  def test_message_no_issue_counts_in_payload
    assert_equal(
      "Code Climate has analyzed this pull request.",
      message_from_payload({})
    )
  end

  def test_message_singular
    assert_equal(
      "Code Climate found 1 new issue and 1 fixed issue.",
      message_from_payload("fixed_issue_count" => 1, "new_issue_count" => 1)
    )
  end

  def test_message_plural
    assert_equal(
      "Code Climate found 2 new issues and 1 fixed issue.",
      message_from_payload("fixed_issue_count" => 1, "new_issue_count" => 2)
    )
  end

  def test_message_only_fixed
    assert_equal(
      "Code Climate found 1 fixed issue.",
      message_from_payload("fixed_issue_count" => 1, "new_issue_count" => 0)
    )
  end

  def test_message_only_new
    assert_equal(
      "Code Climate found 3 new issues.",
      message_from_payload("fixed_issue_count" => 0, "new_issue_count" => 3)
    )
  end

  def test_message_no_new_or_fixed
    assert_equal(
      "Code Climate didn't find any new or fixed issues.",
      message_from_payload("fixed_issue_count" => 0, "new_issue_count" => 0)
    )
  end

private

  def message_from_payload(payload)
    CC::Service::GitHubPullRequests::Presenter.new(payload).success_message
  end
end
