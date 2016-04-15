require "cc/presenters/pull_requests_presenter"

class CC::Service::GitHubPullRequests < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, Axiom::Types::String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo."
    attribute :update_status, Axiom::Types::Boolean,
      label: "Update status?",
      description: "Update the pull request status after analyzing?"
    attribute :base_url, Axiom::Types::String,
      label: "Github API Base URL",
      description: "Base URL for the Github API",
      default: "https://api.github.com"
    attribute :context, Axiom::Types::String,
      label: "Github Context",
      description: "The integration name next to the pull request status",
      default: "codeclimate"

    validates :oauth_token, presence: true
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on GitHub"

  # Just make sure we can access GH using the configured token. Without
  # additional information (github-slug, PR number, etc) we can't test much
  # else.
  def receive_test
    setup_http

    if update_status?
      receive_test_status
    else
      simple_failure("Nothing happened")
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

private

  def update_status?
    [true, "1"].include?(config.update_status)
  end

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

  def update_status_failure
    update_status("failure", presenter.success_message)
  end

  def presenter
    CC::Service::PullRequestsPresenter.new(@payload)
  end

  def update_status_error
    update_status(
      "error",
      @payload["message"] || presenter.error_message
    )
  end

  def update_status_pending
    update_status(
      "pending",
      @payload["message"] || presenter.pending_message
    )
  end

  def update_status(state, description)
    if update_status?
      params = {
        state:       state,
        description: description,
        target_url:  @payload["details_url"],
        context:     config.context,
      }
      @response = service_post(status_url, params.to_json)
    end
  end

  def receive_test_status
    url = base_status_url("0" * 40)
    params = {}
    raw_post(url, params.to_json)
  rescue CC::Service::HTTPError => e
    if e.status == 422
      {
        ok: true,
        params: params.as_json,
        status: e.status,
        endpoint_url: url,
        message: "OAuth token is valid"
      }
    else
      raise
    end
  end

  def setup_http
    http.headers["Content-Type"]  = "application/json"
    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"]    = "Code Climate"
  end

  def status_url
    base_status_url(commit_sha)
  end

  def base_status_url(commit_sha)
    "#{config.base_url}/repos/#{github_slug}/statuses/#{commit_sha}"
  end

  def user_url
    "#{config.base_url}/user"
  end

  def github_slug
    @payload.fetch("github_slug")
  end

  def commit_sha
    @payload.fetch("commit_sha")
  end

  def number
    @payload.fetch("number")
  end

  def response_includes_repo_scope?(response)
    response.headers['x-oauth-scopes'] && response.headers['x-oauth-scopes'].split(/\s*,\s*/).include?("repo")
  end

end
