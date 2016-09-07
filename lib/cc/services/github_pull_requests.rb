require "cc/presenters/pull_requests_presenter"
require "cc/presenters/github_pull_requests_welcome_comment_presenter"

class CC::Service::GitHubPullRequests < CC::PullRequests
  class Config < CC::Service::Config
    attribute :oauth_token, Axiom::Types::String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo."
    attribute :base_url, Axiom::Types::String,
      label: "Github API Base URL",
      description: "Base URL for the Github API",
      default: "https://api.github.com"
    attribute :context, Axiom::Types::String,
      label: "Github Context",
      description: "The integration name next to the pull request status",
      default: "codeclimate"
    attribute :rollout_usernames, Axiom::Types::String,
      label: "Allowed Author's Usernames",
      description: "The GitHub usernames of authors to report status for, comma separated"
    attribute :rollout_percentage, Axiom::Types::Integer,
      label: "Author Rollout Percentage",
      description: "The percentage of users to report status for"
    attribute :welcome_comment_enabled, Axiom::Types::Boolean,
      label: "Welcome comment enabled?",
      description: "Post a welcome comment?",
      default: false
    attribute :welcome_comment_markdown, Axiom::Types::String,
      label: "Welcome comment markdown",
      description: "The body of the welcome comment for first-time contributors to this repo.",
      default: CC::Service::GitHubPullRequestsWelcomeCommentPresenter::DEFAULT_BODY

    validates :oauth_token, presence: true
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on GitHub"

  CANT_POST_COMMENTS_MESSAGE = "Access token is invalid - can't post comments".freeze
  INVALID_TOKEN_MESSAGE = "Access token is invalid.".freeze

  MESSAGES = {
    [true, true] => VALID_TOKEN_MESSAGE,
    [true, nil] => VALID_TOKEN_MESSAGE,
    [false, nil] => CANT_UPDATE_STATUS_MESSAGE,
    [true, false] => CANT_POST_COMMENTS_MESSAGE,
    [false, true] => CANT_UPDATE_STATUS_MESSAGE,
    [false, false] => INVALID_TOKEN_MESSAGE,
  }.freeze

  # Override:
  def receive_test
    setup_http

    tests = [able_to_update_status?, able_to_post_comments?]

    {
      ok: tests.compact.all?,
      message: MESSAGES.fetch(tests),
    }
  end

  def receive_pull_request_opened
    return unless config.welcome_comment_enabled

    setup_http

    @response = service_post(comments_url, { body: welcome_comment_markdown }.to_json)
  end

  private

  def report_status?
    if should_apply_rollout?
      rollout_allowed_by_username? || rollout_allowed_by_percentage?
    else
      true
    end
  end

  def should_apply_rollout?
    (github_login.present? && config.rollout_usernames.present?) ||
      (github_user_id.present? && config.rollout_percentage.present?)
  end

  def rollout_allowed_by_username?
    github_login.present? && config.rollout_usernames.present? &&
      config.rollout_usernames.split(",").map(&:strip).include?(github_login)
  end

  def rollout_allowed_by_percentage?
    github_user_id.present? && config.rollout_percentage.present? &&
      github_user_id % 100 < config.rollout_percentage
  end

  def github_login
    @payload["github_login"]
  end

  def github_user_id
    @payload["github_user_id"]
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
    update_status("failure", presenter.success_message)
  end

  def update_status_error
    update_status(
      "error",
      @payload["message"] || presenter.error_message,
    )
  end

  def update_status_pending
    update_status(
      "pending",
      @payload["message"] || presenter.pending_message,
    )
  end

  def setup_http
    http.headers["Content-Type"] = "application/json"
    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"] = "Code Climate"
  end

  def base_status_url(commit_sha)
    "#{config.base_url}/repos/#{github_slug}/statuses/#{commit_sha}"
  end

  def github_slug
    @payload.fetch("github_slug")
  end

  def response_includes_repo_scope?(response)
    response.headers["x-oauth-scopes"] && response.headers["x-oauth-scopes"].split(/\s*,\s*/).include?("repo")
  end

  def test_status_code
    422
  end

  def user_url
    "#{config.base_url}/user"
  end

  def comments_url
    "#{config.base_url}/repos/#{github_slug}/issues/#{number}/comments"
  end

  def able_to_comment?
    response_includes_repo_scope?(service_get(user_url))
  end

  def welcome_comment_markdown
    GitHubPullRequestsWelcomeCommentPresenter.new(@payload, config).welcome_message
  end

  def able_to_post_comments?
    if config.welcome_comment_enabled
      able_to_comment?
    end
  end
end
