class CC::Service::GitHubPullRequests < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo"
    attribute :update_status, Boolean,
      label: "Update status?",
      description: "Update the pull request status after analyzing?"
    attribute :add_comment, Boolean,
      label: "Add a comment?",
      description: "Comment on the pull request after analyzing?"

    validates :oauth_token, presence: true
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on on GitHub"

  BASE_URL = "https://api.github.com"
  BODY_REGEX = %r{<b>Code Climate</b> has <a href=".*">analyzed this pull request</a>}
  COMMENT_BODY = '<img src="https://codeclimate.com/favicon.png" width="20" height="20" />&nbsp;<b>Code Climate</b> has <a href="%s">analyzed this pull request</a>.'

  # Just make sure we can access GH using the configured token. Without
  # additional information (github-slug, PR number, etc) we can't test much
  # else.
  def receive_test
    setup_http

    http_get("#{BASE_URL}")

    nil
  end

  def receive_pull_request
    setup_http

    case @payload["state"]
    when "pending"
      update_status("pending", "Code Climate is analyzing this code.")
    when "success"
      add_comment
      update_status("success", "Code Climate has analyzed this pull request.")
    end
  end

private

  def update_status(state, description)
    if config.update_status
      body = {
        state:       state,
        description: description,
        target_url:  @payload["details_url"],
      }.to_json

      http_post(status_url, body)
    end
  end

  def add_comment
    if config.add_comment && !comment_present?
      body = {
        body: COMMENT_BODY % @payload["compare_url"]
      }.to_json

      http_post(comments_url, body)
    end
  end

  def comment_present?
    response = http_get(comments_url)
    comments = JSON.parse(response.body)

    comments.any? { |comment| comment["body"] =~ BODY_REGEX }
  end

  def setup_http
    http.headers["Content-Type"]  = "application/json"
    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"]    = "Code Climate"
  end

  def status_url
    "#{BASE_URL}/repos/#{github_slug}/statuses/#{commit_sha}"
  end

  def comments_url
    "#{BASE_URL}/repos/#{github_slug}/issues/#{number}/comments"
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

end
