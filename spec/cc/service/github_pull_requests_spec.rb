describe CC::Service::GitHubPullRequests, type: :service do
  it "test pull request status pending" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "pending",
      "description" => /is analyzing/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "pending")
  end

  it "test pull request status success detailed" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      {},
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "success",
    )
  end

  it "test pull request status failure" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "failure",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.")

    receive_pull_request(
      {},
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "failure",
    )
  end

  it "test pull request status success generic" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => /found 2 new issues and 1 fixed issue/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
                             commit_sha:  "abc123",
                             state:       "success")
  end

  it "test pull request status error" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "error",
      "description" => "Code Climate encountered an error attempting to analyze this pull request.")

    receive_pull_request({}, github_slug: "pbrisbin/foo",
                             commit_sha:  "abc123",
                             state:       "error",
                             message:     nil)
  end

  it "test pull request status error message provided" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "error",
      "description" => "descriptive message")

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
      message:     "descriptive message")
  end

  it "test pull request status skipped" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => /skipped analysis/)

    receive_pull_request({}, github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped")
  end

  it "test pull request coverage status" do
    expect_status_update("pbrisbin/foo", "abc123", "state" => "success",
      "description" => "87% test coverage (+2%)")

    receive_pull_request_coverage({},
      github_slug:     "pbrisbin/foo",
      commit_sha:      "abc123",
      state:           "success",
      covered_percent: 87,
      covered_percent_delta: 2.0)
  end

  it "test pull request status test success" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }

    expect(
      receive_test({}, github_slug: "pbrisbin/foo")[:ok]
    ).to be true
  end

  it "test pull request status test success and comment success" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }
    http_stubs.get("/user") { |env| [200, {'x-oauth-scopes' => "foo,repo,bar" }, ""] }

    response = receive_test({ welcome_comment_enabled: true }, github_slug: "pbrisbin/foo")
    expect(response[:ok]).to be true
    expect(response[:message]).to eq(CC::PullRequests::VALID_TOKEN_MESSAGE)
  end

  it "test pull request status success but not correct permissions to comment" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }
    http_stubs.get("/user") { |env| [200, {'x-oauth-scopes' => "foo,zepo,bar" }, ""] }

    response = receive_test({ welcome_comment_enabled: true }, github_slug: "pbrisbin/foo")
    expect(response[:ok]).to be false
    expect(response[:message]).to eq CC::Service::GitHubPullRequests::CANT_POST_COMMENTS_MESSAGE
  end

  it "test pull request status test doesn't blow up when unused keys present in config" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [422, {}, ""] }

    expect(
      receive_test({ wild_flamingo: true }, github_slug: "pbrisbin/foo")[:ok]
    ).to be true
  end

  it "test pull request status test failure" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [401, {}, ""] }

    response = receive_test({}, github_slug: "pbrisbin/foo")
    expect(response[:ok]).to be false
    expect(response[:message]).to eq CC::PullRequests::CANT_UPDATE_STATUS_MESSAGE
  end

  it "test pull request status test failure and not correct permissions to comment" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |_env| [401, {}, ""] }
    http_stubs.get("/user") { |env| [200, {'x-oauth-scopes' => "foo,zepo,bar" }, ""] }

    response = receive_test({ welcome_comment_enabled: true }, github_slug: "pbrisbin/foo")
    expect(response[:ok]).to be false

    expect(response[:message]).to eq(CC::Service::GitHubPullRequests::INVALID_TOKEN_MESSAGE)
  end

  it "test updating status for pull request unknown state" do
    response = receive_pull_request({}, state: "unknown")

    expect(ok: false, message: "Unknown state").to eq(response)
  end

  it "test updating status for different base url" do
    http_stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") do |env|
      expect(env[:url].to_s).to eq("http://example.com/repos/pbrisbin/foo/statuses/#{"0" * 40}")
      [422, { "x-oauth-scopes" => "gist, user, repo" }, ""]
    end

    expect(
      receive_test({ base_url: "http://example.com" }, github_slug: "pbrisbin/foo")[:ok]
    ).to be true
  end

  it "test updating status for default context" do
    expect_status_update("gordondiggs/ellis", "abc123", "context" => "codeclimate",
                                                        "state" => "pending")

    receive_pull_request({}, github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending")
  end

  it "test updating status for different context" do
    expect_status_update("gordondiggs/ellis", "abc123", "context" => "sup",
      "state" => "pending")

    receive_pull_request({ context: "sup" }, github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending")
  end

  describe "pr status rollout" do
    it "does not send the status if username is not part of rollout" do
      instance = service(
        CC::Service::GitHubPullRequests,
        { oauth_token: "123", rollout_usernames: "sup" },
        { name: "pull_request", github_slug: "gordondiggs/ellis", commit_sha: "abc123", state: "pending", github_login: "abbynormal", github_user_id: 1234 },
      )

      expect(instance).not_to receive(:update_status_pending)

      instance.receive
    end

    it "does not send the status if user not part of percentage" do
      instance = service(
        CC::Service::GitHubPullRequests,
        { oauth_token: "123", rollout_percentage: 20 },
        { name: "pull_request", github_slug: "gordondiggs/ellis", commit_sha: "abc123", state: "pending", github_login: "abbynormal", github_user_id: 1234 },
      )

      expect(instance).not_to receive(:update_status_pending)

      instance.receive
    end

    it "does send the status if username is part of rollout" do
      instance = service(
        CC::Service::GitHubPullRequests,
        { oauth_token: "123", rollout_usernames: "abbynormal", rollout_percentage: 0 },
        { name: "pull_request", github_slug: "gordondiggs/ellis", commit_sha: "abc123", state: "pending", github_login: "abbynormal", github_user_id: 1234 },
      )

      expect_status_update("gordondiggs/ellis", "abc123", "state" => "pending")

      instance.receive
    end

    it "does send the status if user falls under rollout percentage" do
      instance = service(
        CC::Service::GitHubPullRequests,
        { oauth_token: "123", rollout_usernames: "sup", rollout_percentage: 60 },
        { name: "pull_request", github_slug: "gordondiggs/ellis", commit_sha: "abc123", state: "pending", github_login: "abbynormal", github_user_id: 1234 },
      )

      expect_status_update("gordondiggs/ellis", "abc123", "state" => "pending")

      instance.receive
    end
  end

  it "test posting welcome comment to non admin" do
    expect_welcome_comment(
      "gordondiggs/ellis",
      "45",
      does_not_contain: [/customize this message or disable/],
    )

    receive_pull_request_opened(
      { welcome_comment_enabled: true },
      {
        author_can_administrate_repo: false,
      }
    )
  end

  it "test posting welcome comment to admin" do
    expect_welcome_comment(
      "gordondiggs/ellis",
      "45",
      contains: [/is using Code Climate/, /customize this message or disable/, /example.com/]
    )

    receive_pull_request_opened(
      { welcome_comment_enabled: true },
      {
        author_can_administrate_repo: true,
      }
    )
  end

  it "does not post welcome comment when it is not the authors first contribution" do
    receive_pull_request_opened(
      { welcome_comment_enabled: true },
      {
        author_can_administrate_repo: false,
        authors_first_contribution: false,
      }
    )
  end

  it "test posting welcome comment with custom body" do
    expect_welcome_comment(
      "gordondiggs/ellis",
      "45",
      contains: [/Can't wait to review this/],
      does_not_contain: [/is using Code Climate/],
    )

    receive_pull_request_opened(
      {
        welcome_comment_enabled: true,
        welcome_comment_markdown: "Can't wait to review this!",
      },
      {
        author_can_administrate_repo: true,
      }
    )
  end

  it "test no comment when not opted in" do
    receive_pull_request_opened(
      { welcome_comment_enabled: false },
      {
        author_can_administrate_repo: true,
      }
    )
  end

  private

  def expect_welcome_comment(repo, number, contains: [], does_not_contain: [])
    http_stubs.post "repos/#{repo}/issues/#{number}/comments" do |env|
      expect("token 123").to eq(env[:request_headers]["Authorization"])

      body = JSON.parse(env[:body])
      expect(body.keys).to eq(%w[body])

      comment_body = body["body"]
      contains.each do |pattern|
        expect(pattern).to match(comment_body)
      end

      does_not_contain.each do |pattern|
        expect(pattern).to_not match(comment_body)
      end

      [201, {}, {}]
    end
  end

  def expect_status_update(repo, commit_sha, params)
    http_stubs.post "repos/#{repo}/statuses/#{commit_sha}" do |env|
      expect("token 123").to eq(env[:request_headers]["Authorization"])

      body = JSON.parse(env[:body])

      params.each do |k, v|
        expect(v).to match(body[k])
      end

      [201, {}, {}]
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

  def receive_pull_request_opened(config, event_data)
    service_receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      {
        name: "pull_request_opened",
        github_slug: "gordondiggs/ellis",
        number: "45",
        author_github_username: "mrb",
        pull_request_integration_edit_url: "http://example.com/edit",
        authors_first_contribution: true,
      }.merge(event_data),
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
