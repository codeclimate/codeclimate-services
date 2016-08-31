require "base64"
require "cc/presenters/pull_requests_presenter"

class CC::Service::StashPullRequests < CC::Service
  class Config < CC::Service::Config
    attribute :domain, Axiom::Types::String,
      description: "Your Stash host domain (e.g. yourstash.com:PORT, please exclude https://)"
    attribute :username, Axiom::Types::String
    attribute :password, Axiom::Types::Password

    validates :domain, presence: true
    validates :username, presence: true
    validates :password, presence: true
  end

  self.title = "Stash Pull Requests"
  self.description = "Update pull requests on Stash"

  STASH_STATES = {
    "error" => "FAILED",
    "failure" => "FAILED",
    "pending" => "INPROGRESS",
    "skipped" => "SUCCESSFUL",
    "success" => "SUCCESSFUL",
  }.freeze

  def receive_test
    setup_http

    service_get(test_url)

    { ok: true, message: "Test succeeded" }
  rescue HTTPError => e
    { ok: false, message: e.message }
  end

  def receive_pull_request
    setup_http

    params = {
      description: description,
      key: "Code Climate",
      name: "Code Climate",
      state: state,
      url:  @payload["details_url"],
    }
    service_post(url, params.to_json)
  end

  private

  def test_url
    "https://#{config.domain}/rest/api/1.0/users"
  end

  def url
    "https://#{config.domain}/rest/build-status/1.0/commits/#{commit_sha}"
  end

  def commit_sha
    @payload.fetch("commit_sha")
  end

  def description
    return @payload["message"] if @payload["message"]

    case @payload["state"]
    when "pending"
      presenter.pending_message
    when "success", "failure"
      presenter.success_message
    when "skipped"
      presenter.skipped_message
    when "error"
      presenter.error_message
    end
  end

  def state
    STASH_STATES[@payload["state"]]
  end

  def setup_http
    http.headers["Content-Type"] = "application/json"
    http.headers["Authorization"] = "Basic #{auth_token}"
    http.headers["User-Agent"] = "Code Climate"
  end

  # Following Basic Auth headers here:
  # https://developer.atlassian.com/stash/docs/latest/how-tos/example-basic-authentication.html
  def auth_token
    Base64.encode64("#{config.username}:#{config.password}")
  end

  def presenter
    CC::Service::PullRequestsPresenter.new(@payload)
  end
end
