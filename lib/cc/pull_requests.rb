class CC::PullRequests < CC::Service
  VALID_TOKEN_MESSAGE = "Access token is valid.".freeze
  CANT_UPDATE_STATUS_MESSAGE = "Access token is invalid - can't update status.".freeze

  def receive_test
    setup_http

    if able_to_update_status?
      { ok: true, message: VALID_TOKEN_MESSAGE }
    else
      { ok: false, message: CANT_UPDATE_STATUS_MESSAGE }
    end
  end

  def receive_pull_request
    setup_http
    state = @payload["state"]

    if %w[pending success failure skipped error].include?(state) && report_status?
      send("update_status_#{state}")
    else
      @response = simple_failure("Unknown state")
    end

    response
  end

  def receive_pull_request_coverage
    setup_http
    state = @payload["state"]

    if state == "success" && report_status?
      update_coverage_status_success
    else
      @response = simple_failure("Unknown state")
    end

    response
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

  def able_to_update_status?
    raw_post(base_status_url("0" * 40), { state: "success" }.to_json)
  rescue CC::Service::HTTPError => e
    if e.status == test_status_code
      true
    elsif (400..499).cover?(e.status)
      false
    else
      raise
    end
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
