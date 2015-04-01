class CC::Service::GitHubPullRequests::Presenter
  def initialize(payload)
    @fixed_count = payload["fixed_issue_count"]
    @new_count = payload["new_issue_count"]
  end

  def success_message
    if issue_counts_in_payload?
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
