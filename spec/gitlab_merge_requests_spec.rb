require File.expand_path("../helper", __FILE__)

class TestGitlabMergeRequests < CC::Service::TestCase
  it "merge request status pending" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "running",
      "description" => /is analyzing/,
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "pending",
    )
  end

  it "merge request status success detailed" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "success",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.",
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "success",
    )
  end

  it "merge request status failure" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "failed",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.",
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "failure",
    )
  end

  it "merge request status error" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "failed",
      "description" => "Code Climate encountered an error attempting to analyze this pull request.",
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "error",
      message: nil,
    )
  end

  it "merge request status error message provided" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "failed",
      "description" => "I'm sorry Dave, I'm afraid I can't do that",
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "error",
      message: "I'm sorry Dave, I'm afraid I can't do that",
    )
  end

  it "merge request status skipped" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "success",
      "description" => /skipped analysis/,
    )

    receive_merge_request(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "skipped",
    )
  end

  it "merge request coverage status success" do
    expect_status_update(
      "hal/hal9000",
      "abc123",
      "state" => "success",
      "description" => "87% test coverage (+2%)",
    )

    receive_merge_request_coverage(
      {},
      git_url: "ssh://git@gitlab.com/hal/hal9000.git",
      commit_sha: "abc123",
      state: "success",
      covered_percent: 87,
      covered_percent_delta: 2.0,
    )
  end

  it "merge request status test success" do
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |_env| [404, {}, ""] }

    receive_test({}, git_url: "ssh://git@gitlab.com/hal/hal9000.git")[:ok], "Expected test of pull request to be true".should.not == nil
  end

  it "merge request status test failure" do
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |_env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({}, git_url: "ssh://git@gitlab.com/hal/hal9000.git")
    end
  end

  it "merge request unknown state" do
    response = receive_merge_request({}, state: "unknown")

    assert_equal({ ok: false, message: "Unknown state" }, response)
  end

  it "different base url" do
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") do |env|
      env[:url].to_s.should == "https://gitlab.hal.org/api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}"
      [404, {}, ""]
    end

    receive_test({ base_url: "https://gitlab.hal.org" }, git_url: "ssh://git@gitlab.com/hal/hal9000.git")[:ok], "Expected test of pull request to be true".should.not == nil
  end

  private

  def expect_status_update(repo, commit_sha, params)
    @stubs.post "api/v3/projects/#{CGI.escape(repo)}/statuses/#{commit_sha}" do |env|
      env[:request_headers]["PRIVATE-TOKEN"].should == "123"

      body = JSON.parse(env[:body])

      params.each do |k, v|
        v.should === body[k],
          "Unexpected value for #{k}. #{v.inspect} !== #{body[k].inspect}"
      end
    end
  end

  def receive_merge_request(config, event_data)
    receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_merge_request_coverage(config, event_data)
    receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request_coverage", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_test(config, event_data = {})
    receive(
      CC::Service::GitlabMergeRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end
end
