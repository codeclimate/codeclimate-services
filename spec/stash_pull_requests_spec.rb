
class TestStashPullRequests < CC::Service::TestCase
  it "receive test" do
    @stubs.get "/rest/api/1.0/users" do
      [200, {}, "{ 'values': [] }"]
    end

    response = receive_test

    assert_equal({ ok: true, message: "Test succeeded" }, response)
  end

  it "failed receive test" do
    @stubs.get "/rest/api/1.0/users" do
      [401, {}, ""]
    end

    response = receive_test

    assert_equal({ ok: false, message: "API request unsuccessful (401)" }, response)
  end

  it "pull request status pending" do
    expect_status_update("abc123", "state" => "INPROGRESS",
                                   "description" => /is analyzing/)

    receive_pull_request(
      commit_sha: "abc123",
      state: "pending",
    )
  end

  it "pull request status success detailed" do
    expect_status_update("abc123", "state" => "SUCCESSFUL",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      commit_sha: "abc123",
      state: "success",
    )
  end

  it "pull request status failure" do
    expect_status_update("abc123", "state" => "FAILED",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      commit_sha: "abc123",
      state: "failure",
    )
  end

  it "pull request status error" do
    expect_status_update("abc123", "state" => "FAILED",
      "description" => "Code Climate encountered an error attempting to analyze this pull request.")

    receive_pull_request(
      commit_sha: "abc123",
      state: "error",
    )
  end

  it "pull request status error message provided" do
    message = "Everything broke."

    expect_status_update("abc123", "state" => "FAILED",
      "description" => message)

    receive_pull_request(
      commit_sha: "abc123",
      message: message,
      state: "error",
    )
  end

  it "pull request status skipped" do
    expect_status_update("abc123", "state" => "SUCCESSFUL",
      "description" => "Code Climate has skipped analysis of this commit.")

    receive_pull_request(
      commit_sha: "abc123",
      state: "skipped",
    )
  end

  it "failed receive pull request" do
    commit_sha = "abc123"

    @stubs.post("/rest/build-status/1.0/commits/#{commit_sha}") do
      [401, {}, ""]
    end

    assert_raises(CC::Service::HTTPError) do
      receive_pull_request(
        commit_sha: "abc123",
        state: "success",
      )
    end
  end

  private

  def expect_status_update(commit_sha, params)
    @stubs.post("/rest/build-status/1.0/commits/#{commit_sha}") do |env|
      body = JSON.parse(env[:body])

      params.each do |k, v|
        v.should === body[k],
          "Unexpected value for #{k}. #{v.inspect} !== #{body[k].inspect}"
      end
    end
  end

  def default_config
    { domain: "example.com", username: "zaphod", password: "g4rgl3bl4st3r" }
  end

  def receive_pull_request(event_data, config = {})
    receive(
      CC::Service::StashPullRequests,
      default_config.merge(config),
      { name: "pull_request", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_test(config = {}, event_data = {})
    receive(
      CC::Service::StashPullRequests,
      default_config.merge(config),
      { name: "test" }.merge(event_data),
    )
  end
end
