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
    attribute :welcome_comment_enabled, Axiom::Types::Boolean, default: false
    attribute :welcome_comment_markdown, Axiom::Types::String,
      label: "Welcome comment",
      description: "The markdown body of the auto-comment to welcome new contributors",
      default: <<-COMMENT
* This repository is using Code Climate to automatically check for code quality issues.
* You can see results for this analysis in the PR status below.
* You can install [the Code Climate browser extension](https://codeclimate.com/browser) to see analysis without leaving GitHub.

Thanks for your contribution!
      COMMENT


    validates :oauth_token, presence: true
  end

  self.title = "GitHub Pull Requests"
  self.description = "Update pull requests on GitHub"

  private

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

    if should_post_welcome_comment?
      post_welcome_comment
    end
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

  def welcome_comment_implemented?
    true
  end

  def should_post_welcome_comment?
    config.welcome_comment_enabled && @payload.fetch("first_contribution", false)
  end

  HEADER_TEMPLATE = <<-HEADER
Hey, @%s-- Since this is the first PR we've seen from you, here's some things you should know about contributing to %s:

  HEADER

  def welcome_comment_markdown_header
    HEADER_TEMPLATE % [@payload.fetch("author_username"), github_slug]
  end

  ADMIN_ONLY_FOOTER_TEMPLATE = <<-FOOTER

* * *

Quick note: By default, Code Climate will post the above comment on the *first* PR it sees from each contributor. If you'd like to customize this message or disable this, go [here](%s).
  FOOTER

  def admin_only_footer
    ADMIN_ONLY_FOOTER_TEMPLATE % @payload.fetch("pull_request_integration_edit_url")
  end

  def author_is_site_admin?
    @payload.fetch("author_is_site_admin")
  end

  def welcome_comment_markdown
    header = welcome_comment_markdown_header
    body = config.welcome_comment_markdown
    if author_is_site_admin?
      header + body + admin_only_footer
    else
      header + body
    end
  end

  def comments_url
    "#{config.base_url}/repos/#{github_slug}/issues/#{number}/comments"
  end

  def post_welcome_comment
    # This will raise an HTTPError if it doesn't succeed
    formatter = GenericResponseFormatter.new(http_prefix: :welcome_comment_)
    comment_response = service_post(comments_url, { body: welcome_comment_markdown }.to_json, formatter)
    @response.merge!(comment_response)
  end

  def user_url
    "#{config.base_url}/user"
  end

  def check_if_able_to_comment
    response = service_get(user_url)
    {
      able_to_comment_status: response.status,
      able_to_comment_endpoint_url: user_url,
    }.merge(
      ok: response_includes_repo_scope?(response),
    )
  end
end
