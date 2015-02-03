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

  def test_pull_request_status_success
    expect_status_update("pbrisbin/foo", "abc123", {
      "state"       => "success",
      "description" => /has analyzed/,
    })

    receive_pull_request({ update_status: true }, {
      github_slug: "pbrisbin/foo",
      commit_sha:  "abc123",
      state:       "success",
    })
  end

  def test_pull_request_test_success
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({}, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_test_failure
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert !receive_test({}, { github_slug: "pbrisbin/foo" })[:ok], "Expected failed test of pull request"
  end

  def test_pull_request_comment
    stub_existing_comments("pbrisbin/foo", 1, %w[Hey Yo])

    expect_comment("pbrisbin/foo", 1, %r{href="http://example.com">analyzed})

    receive_pull_request({ add_comment: true }, {
      github_slug: "pbrisbin/foo",
      number:      1,
      state:       "success",
      compare_url: "http://example.com",
    })
  end

  def test_pull_request_comment_already_present
    stub_existing_comments("pbrisbin/foo", 1, [
      '<b>Code Climate</b> has <a href="">analyzed this pull request</a>'
    ])

    # With no POST expectation, test will fail if request is made.

    receive_pull_request({ add_comment: true }, {
      github_slug: "pbrisbin/foo",
      number:      1,
      state:       "success",
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
    end
  end

  def receive_pull_request(config, event_data)
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "pull_request" }.merge(event_data)
    )
  end

  def receive_test(config, event_data)
    receive(
      CC::Service::GitHubPullRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test" }.merge(event_data)
    )
  end

end
