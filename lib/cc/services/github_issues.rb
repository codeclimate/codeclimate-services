class CC::Service::GitHubIssues < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo"
    attribute :project, String,
      label: "Project",
      description: "Project name on GitHub (e.g 'thoughtbot/paperclip')"
    attribute :labels, String,
      label: "Labels (comma separated)",
      description: "Comma separated list of labels to apply to the issue"

    validates :oauth_token, presence: true
  end

  self.issue_tracker = true
  self.title = "GitHub Issues"

  BASE_URL = "https://api.github.com"

  def receive_quality
    params = {
      title: "Refactor #{constant_name} from #{rating} on Code Climate",
      body:  details_url,
    }

    if config.labels.present?
      params[:labels] = config.labels.split(",").map(&:strip).reject(&:blank?).compact
    end

    http.headers["Content-Type"] = "application/json"
    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"] = "Code Climate"

    url = "#{BASE_URL}/repos/#{config.project}/issues"
    res = http_post(url, params.to_json)

    body = JSON.parse(res.body)

    {
      id:     body["id"],
      number: body["number"],
      url:    body["html_url"]
    }
  end

end
