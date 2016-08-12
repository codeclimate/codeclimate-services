require File.expand_path('../helper', __FILE__)

class TestGitlabMergeRequests < CC::Service::TestCase
  def test_merge_request_status_pending
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

  def test_merge_request_status_success_detailed
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

  def test_merge_request_status_failure
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

  def test_merge_request_status_error
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

  def test_merge_request_status_error_message_provided
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

  def test_merge_request_status_skipped
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

  def test_merge_request_coverage_status_success
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

  def test_merge_request_status_test_success
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |env| [404, {}, ""] }

    assert receive_test({}, { git_url: "ssh://git@gitlab.com/hal/hal9000.git" })[:ok], "Expected test of pull request to be true"
  end

  def test_merge_request_status_test_failure
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") { |env| [401, {}, ""] }

    assert_raises(CC::Service::HTTPError) do
      receive_test({}, { git_url: "ssh://git@gitlab.com/hal/hal9000.git" })
    end
  end

  def test_merge_request_unknown_state
    response = receive_merge_request({}, { state: "unknown" })

    assert_equal({ ok: false, message: "Unknown state" }, response)
  end

  def test_different_base_url
    @stubs.post("api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}") do |env|
      assert env[:url].to_s == "https://gitlab.hal.org/api/v3/projects/hal%2Fhal9000/statuses/#{"0" * 40}"
      [404, {}, ""]
    end

    assert receive_test({ base_url: "https://gitlab.hal.org" }, { git_url: "ssh://git@gitlab.com/hal/hal9000.git" })[:ok], "Expected test of pull request to be true"
  end

  def test_different_context
    expect_status_update(
      "gordondiggs/ellis",
      "abc123",
      "context" => "sup",
      "state" => "running",
    )

    response = receive_merge_request(
      { context: "sup" },
      git_url: "https://gitlab.com/gordondiggs/ellis.git",
      commit_sha: "abc123",
      state: "pending",
    )
  end

  def test_default_context
    expect_status_update(
      "gordondiggs/ellis",
      "abc123",
      "context" => "codeclimate",
      "state" => "running",
    )

    response = receive_merge_request(
      {},
      git_url: "https://gitlab.com/gordondiggs/ellis.git",
      commit_sha: "abc123",
      state: "pending",
    )
  end

  private

  def expect_status_update(repo, commit_sha, params)
    @stubs.post "api/v3/projects/#{CGI.escape(repo)}/statuses/#{commit_sha}" do |env|
      assert_equal "123", env[:request_headers]["PRIVATE-TOKEN"]

      body = JSON.parse(env[:body])

      params.each do |k, v|
        assert v === body[k],
          "Unexpected value for #{k}. #{v.inspect} !== #{body[k].inspect}"
      end
    end
  end

  def receive_merge_request(config, event_data)
    receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end

  def receive_merge_request_coverage(config, event_data)
    receive(
      CC::Service::GitlabMergeRequests,
      { access_token: "123" }.merge(config),
      { name: "pull_request_coverage", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end

  def receive_test(config, event_data = {})
    receive(
      CC::Service::GitlabMergeRequests,
      { oauth_token: "123" }.merge(config),
      { name: "test", issue_comparison_counts: {'fixed' => 1, 'new' => 2} }.merge(event_data)
    )
  end
end
