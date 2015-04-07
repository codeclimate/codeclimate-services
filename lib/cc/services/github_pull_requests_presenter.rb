require "cc/services/github_pull_requests"

class CC::Service::GitHubPullRequests::Presenter
  def initialize(payload, repo_config)
    issue_comparison_counts = payload["issue_comparison_counts"]

    if issue_comparison_counts
      @fixed_count = issue_comparison_counts["fixed"]
      @new_count = issue_comparison_counts["new"]
    end

    @repo_config = repo_config
  end

  def success_message
    if @repo_config.pr_status_quality_stats?
      if both_issue_counts_zero?
        "Code Climate didn't find any new or fixed issues."
      else
        "Code Climate found #{formatted_issue_counts}."
      end
    else
      "Code Climate has analyzed this pull request."
    end
  end

private

  def both_issue_counts_zero?
    issue_counts.all?(&:zero?)
  end

  def formatted_fixed_issues
    if @fixed_count > 0
      "#{@fixed_count} fixed #{"issue".pluralize(@fixed_count)}"
    else
      nil
    end
  end

  def formatted_new_issues
    if @new_count > 0
      "#{@new_count} new #{"issue".pluralize(@new_count)}"
    else
      nil
    end
  end

  def formatted_issue_counts
    [formatted_new_issues, formatted_fixed_issues].compact.to_sentence
  end

  def issue_counts
    [@new_count, @fixed_count]
  end

  def issue_counts_in_payload?
    issue_counts.all?
  end
end
