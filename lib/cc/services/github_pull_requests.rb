require "cc/presenters/pull_requests_presenter"

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
      description: "The GitHub usernames of authors to report status for, comma separated",
      default: nil
    attribute :rollout_percentage, Axiom::Types::Integer,
      label: "Author Rollout Percentage",
      description: "The percentage of users to report status for",
      default: nil

    validates :oauth_token, presence: true
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on GitHub"

  private

  def report_status?
    if author_username.present? && (config.rollout_usernames.present? || config.rollout_percentage.present?)
      rollout_allowed_by_username? || rollout_allowed_by_percentage?
    else
      true
    end
  end

  def rollout_allowed_by_username?
    config.rollout_usernames.present? &&
      config.rollout_usernames.split(",").map(&:strip).include?(author_username)
  end

  def rollout_allowed_by_percentage?
    config.rollout_percentage.present? &&
      Digest::MD5.hexdigest(author_username).to_i(16) % 100 <= config.rollout_percentage
  end

  def author_username
    @payload["author_username"]
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
end
