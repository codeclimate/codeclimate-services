require "cc/presenters/pull_requests_presenter"

class CC::Service::GitlabMergeRequests < CC::PullRequests
  class Config < CC::Service::Config
    CONTEXT = "codeclimate".freeze

    attribute :access_token, Axiom::Types::Token,
      label: "Access Token",
      description: "A personal access token with permissions for the repo."
    attribute :base_url, Axiom::Types::String,
      label: "GitLab API Base URL",
      description: "Base URL for the GitLab API",
      default: "https://gitlab.com"

    def context
      CONTEXT
    end
  end

  self.title = "GitLab Merge Requests"
  self.description = "Update merge requests on GitLab"

  private

  def report_status?
    true
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

  def update_status_error
    update_status(
      "failed",
      @payload["message"] || presenter.error_message,
    )
  end

  def update_status_pending
    update_status(
      "running",
      @payload["message"] || presenter.pending_message,
    )
  end

  def setup_http
    http.headers["Content-Type"] = "application/json"
    http.headers["PRIVATE-TOKEN"] = config.access_token
    http.headers["User-Agent"] = "Code Climate"
  end

  def base_status_url(commit_sha)
    "#{config.base_url}/api/v3/projects/#{CGI.escape(slug)}/statuses/#{commit_sha}"
  end

  def slug
    git_url.path.gsub(/(^\/|.git$)/, "")
  end

  def test_status_code
    404
  end
end
