require_relative 'github_pull_requests'

class CC::Service::GithubEnterprisePullRequest < CC::Service::GitHubPullRequests
  class Config < CC::Service::Config
    attribute :oauth_token, String,
              label: "OAuth Token",
              description: "A personal OAuth token with permissions for the repo. The owner of the token will be the author of the pull request update."
    attribute :base_url, String,
              label: "Base API URL",
              description: "The Base URL to your Github Enterprise instance."

    validates :oauth_token, presence: true
    validates :base_url, presence: true
  end

  def base_status_url(commit_sha)
    "#{config.base_url}/repos/#{github_slug}/statuses/#{commit_sha}"
  end

  def user_url
    "#{config.base_url}/user"
  end
end
