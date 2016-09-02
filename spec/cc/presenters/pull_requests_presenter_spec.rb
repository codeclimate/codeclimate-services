require "cc/presenters/pull_requests_presenter"

describe CC::Service::PullRequestsPresenter, type: :service do
  it "message singular" do
    expect("Code Climate found 1 new issue and 1 fixed issue.").to eq(build_presenter("fixed" => 1, "new" => 1).success_message)
  end

  it "message plural" do
    expect("Code Climate found 2 new issues and 1 fixed issue.").to eq(build_presenter("fixed" => 1, "new" => 2).success_message)
  end

  it "message only fixed" do
    expect("Code Climate found 1 fixed issue.").to eq(build_presenter("fixed" => 1, "new" => 0).success_message)
  end

  it "message only new" do
    expect("Code Climate found 3 new issues.").to eq(build_presenter("fixed" => 0, "new" => 3).success_message)
  end

  it "message no new or fixed" do
    expect("Code Climate didn't find any new or fixed issues.").to eq(build_presenter("fixed" => 0, "new" => 0).success_message)
  end

  it "message coverage same" do
    expect("85% test coverage").to eq(build_presenter({}, "covered_percent" => 85, "covered_percent_delta" => 0).coverage_message)
  end

  it "message coverage up" do
    expect("85.5% test coverage (+2.46%)").to eq(build_presenter({}, "covered_percent" => 85.5, "covered_percent_delta" => 2.4567).coverage_message)
  end

  it "message coverage down" do
    expect("85.35% test coverage (-3%)").to eq( build_presenter({}, "covered_percent" => 85.348, "covered_percent_delta" => -3.0).coverage_message)
  end

  private

  def build_payload(issue_counts)
    { "issue_comparison_counts" => issue_counts }
  end

  def build_presenter(issue_counts, payload = {})
    CC::Service::PullRequestsPresenter.new(build_payload(issue_counts).merge(payload))
  end
end
