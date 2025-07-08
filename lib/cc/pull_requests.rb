class CC::PullRequests < CC::Service
  def receive_test
    setup_http

    receive_test_status
  end

  def receive_pull_request
    receive_request(%w[pending success failure skipped error], :update_status)
  end

  def receive_pull_request_coverage
    receive_request("success", :update_coverage_status)
  end

  def receive_pull_request_diff_coverage
    receive_request(%w[pending skipped], :update_diff_coverage_status)
  end

  def receive_pull_request_total_coverage
    receive_request(%w[pending skipped], :update_total_coverage_status)
  end

  private

  def report_status?
    raise NotImplementedError
  end

  def simple_failure(message)
    { ok: false, message: message }
  end

  def response
    @response || simple_failure("Nothing happened")
  end

  def update_status_skipped
    raise NotImplementedError
  end

  def update_status_success
    raise NotImplementedError
  end

  def update_coverage_status_success
    raise NotImplementedError
  end

  def update_diff_coverage_status_skipped
    raise NotImplementedError
  end

  def update_diff_coverage_status_pending
    raise NotImplementedError
  end

  def update_total_coverage_status_skipped
    raise NotImplementedError
  end

  def update_total_coverage_status_pending
    raise NotImplementedError
  end

  def update_status_failure
    raise NotImplementedError
  end

  def update_status_error
    raise NotImplementedError
  end

  def update_status_pending
    raise NotImplementedError
  end

  def test_status_code
    raise NotImplementedError
  end

  def hard_fail_migration_notice_enabled?
    false
  end

  def receive_test_status
    url = base_status_url("0" * 40)
    params = { state: "success" }
    raw_post(url, params.to_json)
  rescue CC::Service::HTTPError => e
    if e.status == test_status_code
      {
        ok: true,
        params: params.as_json,
        status: e.status,
        endpoint_url: url,
        message: "Access token is valid",
      }
    else
      raise
    end
  end

  def receive_request(*permitted_statuses, call_method)
    setup_http
    state = @payload["state"]

    if permitted_statuses.flatten.include?(state) && report_status?
      send(call_method.to_s + "_#{state}")
      send_hard_fail_migration_notice_commit_status(commit_sha)
    else
      @response = simple_failure("Unknown state")
    end

    response
  end

  def send_hard_fail_migration_notice_commit_status(commit_sha)
    return unless hard_fail_migration_notice_enabled?

    # Temporarily store the original target_url and replace it
    original_target_url = @payload["details_url"]
    @payload["details_url"] = "https://docs.qlty.sh/migration/guide"
    
    update_status(
      "failure",
      "Code Climate plans to stop sending commit statuses to GitHub. Migrate to Qlty.sh for continued support.",
      "codeclimate/migrate-to-qlty-sh"
    )
    
    # Restore the original target_url
    @payload["details_url"] = original_target_url
  end

  def presenter
    CC::Service::PullRequestsPresenter.new(@payload)
  end

  def update_status(state, description, context = config.context)
    params = {
      context: context,
      description: description,
      state: state,
      target_url: @payload["details_url"],
    }
    @response = service_post(status_url, params.to_json)
  end

  def status_url
    base_status_url(commit_sha)
  end

  def base_status_url(_commit_sha)
    raise NotImplementedError
  end

  def setup_http
    raise NotImplementedError
  end

  def commit_sha
    @payload.fetch("commit_sha")
  end

  def number
    @payload.fetch("number")
  end

  def git_url
    @git_url ||= URI.parse(@payload.fetch("git_url"))
  end
end
