class CC::Service::GitHubPullRequests < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo. The owner of the token will be the author of the pull request status."

    validates :oauth_token, presence: true
  end

  class ResponseAggregator
    def initialize(status_response)
      @status_response = status_response
    end

    def response
      error_message ||= "Unable to update status: #{@status_response[:message]}"
      @status_response[:ok] ? @status_response : { ok: false, message: error_message}
    end
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on GitHub"

  BASE_URL = "https://api.github.com"
  BODY_REGEX = %r{<b>Code Climate</b> has <a href=".*">analyzed this pull request</a>}

  # Just make sure we can access GH using the configured token. Without
  # additional information (github-slug, PR number, etc) we can't test much
  # else.
  def receive_test
    setup_http
    ResponseAggregator.new(receive_test_status).response
  end

  def receive_pull_request
    setup_http

    case @payload["state"]
    when "pending"
      update_status("pending", "Code Climate is analyzing this code.")
    when "success"
      update_status("success", "Code Climate has analyzed this pull request.")
    end
  end

private

  def update_status(state, description)
    body = {
      state:       state,
      description: description,
      target_url:  @payload["details_url"],
      context:     "codeclimate"
    }.to_json

    http_post(status_url, body)
  end

  def receive_test_status
    http_post(base_status_url("0" * 40), "{}")

  rescue HTTPError => ex
    if ex.status == 422 # response message: "No commit found for SHA"
      { ok: true, message: "OAuth token is valid" }
    else ex.status == 401 # response message: "Bad credentials"
      { ok: false, message: ex.message }
    end
  rescue => ex
    { ok: false, message: ex.message }
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
    "#{BASE_URL}/repos/#{github_slug}/statuses/#{commit_sha}"
  end

  def user_url
    "#{BASE_URL}/user"
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
