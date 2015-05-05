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
      "description" => /encountered an error/,
    })

    receive_pull_request({ update_status: true }, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "error",
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
    })
  end


  def test_no_comment_for_skips_regardless_of_add_comment_config
    # With no POST expectation, test will fail if request is made.

    receive_pull_request({ add_comment: true }, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "skipped",
    })
  end

  def test_pull_request_status_test_success
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_failure
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })
    end
  end

  def test_pull_request_comment_test_success
    @stubs.get("/user") { |env| [200, { "x-oauth-scopes" => "gist, user, repo" }, ""] }

    assert receive_test({ add_comment: true })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_comment_test_failure_insufficient_permissions
    @stubs.get("/user") { |env| [200, { "x-oauth-scopes" => "gist, user" }, ""] }

    assert !receive_test({ add_comment: true })[:ok], "Expected failed test of pull request"
  end

  def test_pull_request_comment_test_failure_bad_token
    @stubs.get("/user") { |env| [401, {}, ""] }

    assert !receive_test({ add_comment: true })[:ok], "Expected failed test of pull request"
  end

  def test_pull_request_failure_on_status_requesting_both
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({ update_status: true, add_comment: true }, { github_slug: "pbrisbin/foo" })
    end
  end

  def test_pull_request_failure_on_comment_requesting_both
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }
    @stubs.get("/user") { |env| [401, { "x-oauth-scopes" => "gist, user, repo" }, ""] }

    assert_false receive_test({ update_status: true, add_comment: true }, { github_slug: "pbrisbin/foo" })[:ok]
  end

  def test_pull_request_success_both
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }
    @stubs.get("/user") { |env| [200, { "x-oauth-scopes" => "gist, user, repo" }, ""] }

    assert receive_test({ update_status: true, add_comment: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_comment
    stub_existing_comments("pbrisbin/foo", 1, %w[Hey Yo])

    expect_comment("pbrisbin/foo", 1, %r{href="http://example.com">analyzed})

    receive_pull_request({ add_comment: true }, {
      github_slug: "pbrisbin/foo",
      number:      1,
      state:       "success",
      compare_url: "http://example.com",
      issue_comparison_counts: {
        "fixed" => 2,
        "new"   => 1,
      }
    })
  end

  def test_pull_request_comment_already_present
    stub_existing_comments("pbrisbin/foo", 1, [
      '<b>Code Climate</b> has <a href="">analyzed this pull request</a>'
    ])

    # With no POST expectation, test will fail if request is made.

    response = receive_pull_request({
      add_comment: true,
      update_status: false
    }, {
      github_slug: "pbrisbin/foo",
      number:      1,
      state:       "success",
    })

    assert_equal({ ok: true, message: "Comment already present" }, response)
  end

  def test_pull_request_unknown_state
    response = receive_pull_request({}, { state: "unknown" })

    assert_equal({ ok: false, message: "Unknown state" }, response)
  end

  def test_pull_request_nothing_happened
    response = receive_pull_request({}, { state: "success" })

    assert_equal({ ok: false, message: "Nothing happened" }, response)
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

  def stub_existing_comments(repo, number, bodies)
    body = bodies.map { |b| { body: b } }.to_json

    @stubs.get("repos/#{repo}/issues/#{number}/comments") { [200, {}, body] }
  end

  def expect_comment(repo, number, content)
    @stubs.post "repos/#{repo}/issues/#{number}/comments" do |env|
      body = JSON.parse(env[:body])
      assert_equal "token 123", env[:request_headers]["Authorization"]
      assert content === body["body"],
        "Unexpected comment body. #{content.inspect} !== #{body["body"].inspect}"
      [200, {}, '{"id": 2}']
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
