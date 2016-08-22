require File.expand_path('../helper', __FILE__)

class TestGitHubPullRequests < CC::Service::TestCase
  def test_pull_request_status_pending
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "pending",
      "description" => /is analyzing/,
    })

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "pending",
    })
  end

  def test_pull_request_status_success_detailed
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "success",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.",
    })

    receive_pull_request(
      {},
      {
        github_slug: "pbrisbin/foo",
        commit_sha:  "abc123",
        state:       "success"
      }
    )
  end

  def test_pull_request_status_failure
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "failure",
      "description" => "Code Climate found 2 new issues and 1 fixed issue.",
    })

    receive_pull_request(
      {},
      {
        github_slug: "pbrisbin/foo",
        commit_sha:  "abc123",
        state:       "failure"
      }
    )
  end

  def test_pull_request_status_success_generic
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "success",
      "description" => /found 2 new issues and 1 fixed issue/,
    })

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "success",
    })
  end

  def test_pull_request_status_error
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "error",
      "description" => "Code Climate encountered an error attempting to analyze this pull request.",
    })

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
      message:     nil,
    })
  end

  def test_pull_request_status_error_message_provided
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "error",
      "description" => "descriptive message",
    })

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
      message:     "descriptive message",
    })
  end

  def test_pull_request_status_skipped
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "success",
      "description" => /skipped analysis/,
    })

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped",
    })
  end

  def test_pull_request_coverage_status
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "success",
      "description" => "87% test coverage (+2%)",
    })

    receive_pull_request_coverage({},
      github_slug:     "pbrisbin/foo",
      commit_sha:      "abc123",
      state:           "success",
      covered_percent: 87,
      covered_percent_delta: 2.0,
    )
  end

  def test_pull_request_status_test_success
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({}, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_doesnt_blow_up_when_unused_keys_present_in_config
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({ wild_flamingo: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_failure
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({}, { github_slug: "pbrisbin/foo" })
    end
  end

  def test_pull_request_unknown_state
    response = receive_pull_request({}, { state: "unknown" })

    assert_equal({ ok: false, message: "Unknown state" }, response)
  end

  def test_different_base_url
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") do |env|
      assert env[:url].to_s == "http://example.com/repos/pbrisbin/foo/statuses/#{"0" * 40}"
      [422, { "x-oauth-scopes" => "gist, user, repo" }, ""]
    end

    assert receive_test({ base_url: "http://example.com" }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_default_context
    expect_status_update("gordondiggs/ellis", "abc123", {
      "context" => "codeclimate",
      "state" => "pending",
    })

    receive_pull_request({}, {
      github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending",
    })
  end

  def test_different_context
    expect_status_update("gordondiggs/ellis", "abc123", {
      "context" => "sup",
      "state" => "pending",
    })

    receive_pull_request({ context: "sup" }, {
      github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending",
    })
  end

private

  def expect_status_update(repo, commit_sha, params)
    @stubs.post "repos/#{repo}/statuses/#{commit_sha}" do |env|
      assert_equal "token 123", env[:request_headers]["Authorization"]

      body = JSON.parse(env[:body])

      params.each do |k, v|
        assert v === body[k],
          "Unexpected value for #{k}. #{v.inspect} !== #{body[k].inspect}"
      end
    end
  end

  def receive_pull_request(config, event_data)
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "pull_request", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end

  def receive_pull_request_coverage(config, event_data)
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "pull_request_coverage", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end

  def receive_test(config, event_data = {})
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end
end
