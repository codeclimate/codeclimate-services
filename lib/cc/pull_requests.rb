class CC::PullRequests < CC::Service
  ABLE_TO_UPDATE_STATUS_MESSAGE = "Access token is valid".freeze
  ABLE_TO_UPDATE_STATUS_AND_COMMENT_MESSAGE = "Access token is valid".freeze
  ABLE_TO_UPDATE_STATUS_BUT_NOT_COMMENT_MESSAGE = "OAuth token requires 'repo' scope to post comments.".freeze

  def receive_test
    setup_http

    able_to_update_status_response = check_if_able_to_update_status

    if welcome_comment_implemented? && config.welcome_comment_enabled
      able_to_comment_response = check_if_able_to_comment

      ok, message =
        if able_to_comment_response.fetch(:ok)
          [true, ABLE_TO_UPDATE_STATUS_AND_COMMENT_MESSAGE]
        else
          [false, ABLE_TO_UPDATE_STATUS_BUT_NOT_COMMENT_MESSAGE]
        end

      able_to_comment_response.merge(able_to_update_status_response).
        merge(ok: ok, message: message)
    else
      able_to_update_status_response
    end
  end

  def receive_pull_request
    setup_http
    state = @payload["state"]

    if %w[pending success failure skipped error].include?(state)
      send("update_status_#{state}")
    else
      @response = simple_failure("Unknown state")
    end

    response
  end

  def receive_pull_request_coverage
    setup_http
    state = @payload["state"]

    if state == "success"
      update_coverage_status_success
    else
      @response = simple_failure("Unknown state")
    end

    response
  end

  private

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

  def check_if_able_to_update_status
    url = base_status_url("0" * 40)
    params = { state: "success" }
    raw_post(url, params.to_json)
  rescue CC::Service::HTTPError => e
    if e.status == test_status_code
      {
        ok: true,
        able_to_update_status_params: params.as_json,
        able_to_update_status_status: e.status,
        able_to_update_status_endpoint_url: url,
        message: ABLE_TO_UPDATE_STATUS_MESSAGE,
      }
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
    formatter = GenericResponseFormatter.new(http_prefix: :update_status_)
    @response = service_post(status_url, params.to_json, formatter)
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

  def welcome_comment_implemented?
    false
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
