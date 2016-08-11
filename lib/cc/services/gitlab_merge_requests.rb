require "cc/presenters/pull_requests_presenter"

class CC::Service::GitlabMergeRequests < CC::Service
  class Config < CC::Service::Config
    attribute :access_token, Axiom::Types::String,
      label: "Access Token",
      description: "A personal access token with permissions for the repo."
    attribute :context, Axiom::Types::String,
      label: "Context",
      description: "The integration name for the merge request status",
      default: "codeclimate"
    attribute :base_url, Axiom::Types::String,
      label: "GitLab API Base URL",
      description: "Base URL for the GitLab API",
      default: "https://gitlab.com"
  end

  self.title = "GitLab Merge Requests"
  self.description = "Update merge requests on GitLab"

  def receive_test
    setup_http

    receive_test_status
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
    update_status("success", presenter.skipped_message)
  end

  def update_status_success
    update_status("success", presenter.success_message)
  end

  def update_coverage_status_success
    update_status("success", presenter.coverage_message, "#{config.context}/coverage")
  end

  def update_status_failure
    update_status("failed", presenter.success_message)
  end

  def presenter
    CC::Service::PullRequestsPresenter.new(@payload)
  end

  def update_status_error
    update_status(
      "failed",
      @payload["message"] || presenter.error_message
    )
  end

  def update_status_pending
    update_status(
      "running",
      @payload["message"] || presenter.pending_message
    )
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

  def receive_test_status
    url = base_status_url("0" * 40)
    params = {}
    raw_post(url, params.to_json)
  rescue CC::Service::HTTPError => e
    if e.status == 404
      {
        ok: true,
        params: params.as_json,
        status: e.status,
        endpoint_url: url,
        message: "Access token is valid"
      }
    else
      raise
    end
  end

  def setup_http
    http.headers["Content-Type"] = "application/json"
    http.headers["PRIVATE-TOKEN"] = config.access_token
    http.headers["User-Agent"] = "Code Climate"
  end

  def status_url
    base_status_url(commit_sha)
  end

  def base_status_url(commit_sha)
    "#{config.base_url}/api/v3/projects/#{CGI.escape(slug)}/statuses/#{commit_sha}"
  end

  def slug
    git_url.path.gsub(/(^\/|.git$)/, "")
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

  def response_includes_repo_scope?(response)
    response.headers['x-oauth-scopes'] && response.headers['x-oauth-scopes'].split(/\s*,\s*/).include?("repo")
  end
end
