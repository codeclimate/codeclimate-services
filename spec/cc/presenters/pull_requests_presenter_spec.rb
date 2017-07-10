require "cc/presenters/pull_requests_presenter"

describe CC::Service::PullRequestsPresenter, type: :service do
  it "message singular" do
    expect(build_presenter("fixed" => 1, "new" => 1).success_message).
      to eq("1 issue to fix")
  end

  it "message plural" do
    expect(build_presenter("fixed" => 1, "new" => 2).success_message).
      to eq("2 issues to fix")
  end

  it "message only fixed" do
    expect(build_presenter("fixed" => 1, "new" => 0).success_message).
      to eq("1 fixed issue")
  end

  it "message only new" do
    expect(build_presenter("fixed" => 0, "new" => 3).success_message).
      to eq("3 issues to fix")
  end

  it "message no new or fixed" do
    expect(build_presenter("fixed" => 0, "new" => 0).success_message).
      to eq("All good!")
  end

  it "message coverage same" do
    expect("85%").to eq(build_presenter({}, "covered_percent" => 85, "covered_percent_delta" => 0).coverage_message)
  end

  it "message coverage up" do
    expect("85.5% (+2.46%)").to eq(build_presenter({}, "covered_percent" => 85.5, "covered_percent_delta" => 2.4567).coverage_message)
  end

  it "message coverage down" do
    expect("85.35% (-3%)").to eq( build_presenter({}, "covered_percent" => 85.348, "covered_percent_delta" => -3.0).coverage_message)
  end

  it "message approved" do
    expect(build_presenter({"fixed" => 1, "new" => 1}, { "approved_by" => "FooBar"}).success_message).
      to eq("Approved by FooBar.")
  end

  it "message approved is empty string" do
    expect(build_presenter({"fixed" => 1, "new" => 1}, { "approved_by" => ""}).success_message).
      to eq("1 issue to fix")
  end

  private

  def build_payload(issue_counts)
    { "issue_comparison_counts" => issue_counts }
  end

  def build_presenter(issue_counts, payload = {})
    CC::Service::PullRequestsPresenter.new(build_payload(issue_counts).merge(payload))
  end
end
