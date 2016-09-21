describe CC::Service::GitlabMergeRequests, type: :service do
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
    http_stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |_env| [404, {}, ""] }

    expect(receive_test({}, git_url: "ssh://git@gitlab.com/hal/hal9000.git")[:ok]).to eq(true)
  end

  it "merge request status test failure" do
    http_stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |_env| [401, {}, ""] }

    expect { receive_test({}, git_url: "ssh://git@gitlab.com/hal/hal9000.git") }.to raise_error(CC::Service::HTTPError)
  end

  it "merge request unknown state" do
    response = receive_merge_request({}, state: "unknown")

    expect({ ok: false, message: "Unknown state" }).to eq(response)
  end

  it "different base url" do
    stub_resolv("gitlab.hal.org", "1.1.1.2")

    http_stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") do |env|
      expect(env[:url].to_s).to eq("https://1.1.1.2/api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}")
      [404, {}, ""]
    end

    expect(receive_test({ base_url: "https://gitlab.hal.org" }, git_url: "ssh://git@gitlab.com/hal/hal9000.git")[:ok]).to eq(true)
  end

  context "SafeWebhook" do
    it "rewrites the request to be for the resolved IP" do
      stub_resolv("my.gitlab.com", "1.1.1.2")

      http_stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") do |env|
        expect(env[:url].to_s).to eq("https://1.1.1.2/api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}")
        expect(env[:request_headers][:Host]).to eq("my.gitlab.com")
        [404, {}, ""]
      end

      expect(receive_test({ base_url: "https://my.gitlab.com" }, git_url: "ssh://git@gitlab.com/hal/hal9000.git")[:ok]).to eq(true)
    end

    it "validates that the host doesn't resolve to something internal" do
      stub_resolv("my.gitlab.com", "127.0.0.1")

      expect do
        receive_test({ base_url: "https://my.gitlab.com" }, git_url: "")
      end.to raise_error(CC::Service::SafeWebhook::InvalidWebhookURL)

      stub_resolv("my.gitlab.com", "10.0.0.9")

      expect do
        receive_test({ base_url: "https://my.gitlab.com" }, git_url: "")
      end.to raise_error(CC::Service::SafeWebhook::InvalidWebhookURL)
    end
  end

  private

  def expect_status_update(repo, commit_sha, params)
    http_stubs.post "api/v3/projects/#{CGI.escape(repo)}/statuses/#{commit_sha}" do |env|
      expect(env[:request_headers]["PRIVATE-TOKEN"]).to eq("123")

      body = JSON.parse(env[:body])

      params.each do |k, v|
        expect(v).to match(body[k])
      end
    end
  end

  def receive_merge_request(config, event_data)
    service_receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_merge_request_coverage(config, event_data)
    service_receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request_coverage", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end

  def receive_test(config, event_data = {})
    service_receive(
      CC::Service::GitlabMergeRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: { "fixed" => 1, "new" => 2 } }.merge(event_data),
    )
  end
end
