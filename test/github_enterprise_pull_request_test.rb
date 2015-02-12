require File.expand_path('../helper', __FILE__)

class TestGithubEnterprisePullRequests < CC::Service::TestCase
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

  def test_pull_request_status_test_success
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [422, {}, ""] }

    assert receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected test of pull request to be true"
  end

  def test_pull_request_status_test_failure
    @stubs.post("/repos/pbrisbin/foo/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert !receive_test({ update_status: true }, { github_slug: "pbrisbin/foo" })[:ok], "Expected failed test of pull request"
  end

  def test_response_aggregator_success
    response = aggregrate_response({ok: true, message: "OK"},)
    assert_equal response, { ok: true, message: "OK" }
  end

  def test_response_aggregator_failure_status
    response = aggregrate_response({ok: false, message: "Bad Token"})
    assert !response[:ok], "Expected invalid response because status response is invalid"
    assert_match /Bad Token/, response[:message]
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
      CC::Service::GithubEnterprisePullRequest,
      { oauth_token: "123", base_url: "http://github.test.com" }.merge(config),
      { name: "pull_request" }.merge(event_data)
    )
  end

  def receive_test(config, event_data = {})
    receive(
      CC::Service::GithubEnterprisePullRequest,
      { oauth_token: "123", base_url: "http://github.test.com" }.merge(config),
      { name: "test" }.merge(event_data)
    )
  end

  def aggregrate_response(status_response)
    CC::Service::GithubEnterprisePullRequest::ResponseAggregator.new(status_response).response
  end

end
