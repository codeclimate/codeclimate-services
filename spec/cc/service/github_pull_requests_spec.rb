describe CC::Service::GitHubPullRequests, type: :service do
  it "pull request status pending" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "pending",
      "description" => /is analyzing/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "pending")
  end

  it "pull request status success detailed" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      {},
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "success",
    )
  end

  it "pull request status failure" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "failure",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      {},
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "failure",
    )
  end

  it "pull request status success generic" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => /found 2 new issues and 1 fixed issue/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
                             commit_sha:  "abc123",
                             state:       "success")
  end

  it "pull request status error" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "error",
      "description" => "Code Climate encountered an error attempting to analyze this pull request.")

    receive_pull_request({}, github_slug: "pbrisbin/foo",
                             commit_sha:  "abc123",
                             state:       "error",
                             message:     nil)
  end

  it "pull request status error message provided" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "error",
      "description" => "descriptive message")

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
      message:     "descriptive message")
  end

  it "pull request status skipped" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => /skipped analysis/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped")
  end

  it "pull request coverage status" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => "87% test coverage (+2%)")

    receive_pull_request_coverage({},
      github_slug:     "pbrisbin/foo",
      commit_sha:      "abc123",
      state:           "success",
      covered_percent: 87,
      covered_percent_delta: 2.0)
  end

  it "pull request status test success" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }

    expect(receive_test({}, github_slug: "pbrisbin/foo")[:ok]).to eq(true)
  end

  it "pull request status test doesnt blow up when unused keys present in config" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }

    expect(receive_test({ wild_flamingo: true }, github_slug: "pbrisbin/foo")[:ok]).to eq(true)
  end

  it "pull request status test failure" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [401, {}, ""] }

    expect { receive_test({}, github_slug: "pbrisbin/foo") }.to raise_error(CC::Service::HTTPError)
  end

  it "pull request unknown state" do
    response = receive_pull_request({}, state: "unknown")

    expect({ ok: false, message: "Unknown state" }).to eq(response)
  end

  it "different base url" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") do |env|
      expect(env[:url].to_s).to eq("http://example.com/repos/pbrisbin/foo/statuses/#{"0" * 40}")
      [422, { "x-oauth-scopes" => "gist, user, repo" }, ""]
    end

    expect(receive_test({ base_url: "http://example.com" }, github_slug: "pbrisbin/foo")[:ok]).to eq(true)
  end

  it "default context" do
    expect_status_update("gordondiggs/ellis", "abc123", "context" => "codeclimate",
                                                        "state" => "pending")

    receive_pull_request({}, github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending")
  end

  it "different context" do
    expect_status_update("gordondiggs/ellis", "abc123", "context" => "sup",
      "state" => "pending")

    receive_pull_request({ context: "sup" }, github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending")
  end

  private

  def expect_status_update(repo, commit_sha, params)
    http_stubs.post "repos/#{repo}/statuses/#{commit_sha}" do |env|
      expect(env[:request_headers]["Authorization"]).to eq("token 123")

      body = JSON.parse(env[:body])

      params.each do |k, v|
        expect(v).to match(body[k])
      end
    end
  end

  def receive_pull_request(config, event_data)
    service_receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "pull_request", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_pull_request_coverage(config, event_data)
    service_receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "pull_request_coverage", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_test(config, event_data = {})
    service_receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end
end
