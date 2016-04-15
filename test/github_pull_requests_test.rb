require File.expand_path('../helper', __FILE__)

class TestGitHubPullRequests < CC::Service::TestCase
  def test_pull_request_status_pending
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "pending",
      "description" => /is analyzing/,
    })

    receive_pull_request({ update_status: true }, {
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
      { update_status: true },
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
      { update_status: true },
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

    receive_pull_request({ update_status: true }, {
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

    receive_pull_request({ update_status: true }, {
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

    receive_pull_request({ update_status: true }, {
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

    receive_pull_request({ update_status: true }, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped",
    })
  end

  def test_no_status_update_for_skips_when_update_status_config_is_falsey
    # With no POST expectation, test will fail if request is made.

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped",
    })
  end

  def test_no_status_update_for_pending_when_update_status_config_is_falsey
    # With no POST expectation, test will fail if request is made.

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "pending",
    })
  end

  def test_no_status_update_for_error_when_update_status_config_is_falsey
    # With no POST expectation, test will fail if request is made.

    receive_pull_request({}, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
      message:     nil,
    })
  end

  def test_pull_request_status_test_success
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_doesnt_blow_up_when_unused_keys_present_in_config
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({ update_status: true, add_comment: true, wild_flamingo: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_failure
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })
    end
  end

  def test_pull_request_unknown_state
    response = receive_pull_request({}, { state: "unknown" })

    assert_equal({ ok: false, message: "Unknown state" }, response)
  end

  def test_pull_request_nothing_happened
    response = receive_pull_request({}, { state: "success" })

    assert_equal({ ok: false, message: "Nothing happened" }, response)
  end

  def test_different_base_url
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") do |env|
      assert env[:url].to_s == "http://example.com/repos/pbrisbin/foo/statuses/#{"0" * 40}"
      [422, { "x-oauth-scopes" => "gist, user, repo" }, ""]
    end

    assert receive_test({ update_status: true, base_url: "http://example.com" }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_default_context
    expect_status_update("gordondiggs/ellis", "abc123", {
      "context" => "codeclimate",
      "state" => "pending",
    })

    response = receive_pull_request({ update_status: true }, {
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

    response = receive_pull_request({ context: "sup", update_status: true }, {
      github_slug: "gordondiggs/ellis",
      commit_sha:  "abc123",
      state:       "pending",
    })
  end

  def test_config_coerce_bool_true
    c = CC::Service::GitHubPullRequests::Config.new(oauth_token: "a1b2c3", update_status: "1")
    assert c.valid?
    assert_equal true, c.update_status
  end

  def test_config_coerce_bool_false
    c = CC::Service::GitHubPullRequests::Config.new(oauth_token: "a1b2c3", update_status: "0")
    assert c.valid?
    assert_equal false, c.update_status
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

  def receive_test(config, event_data = {})
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end
end
