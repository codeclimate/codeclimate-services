class CC::Service::GitHubIssues < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, String,
      description: "A personal OAuth token with permissions for the repo"
    attribute :labels, String,
      label: "Labels (comma separated)",
      description: "Comma separated list of labels to apply to the issue"

    validates :oauth_token, presence: true
  end

  self.issue_tracker = true

  BASE_URL = "https://api.github.com"

  def receive_unit
    params = {
      title:  "Title",
      body:   "Body"
    }

    if config.labels.present?
      params[:labels] = config.labels.split(",").map(&:strip).reject(&:blank?).compact
    end

    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"] = "Code Climate"

    url = "#{BASE_URL}/repos/brynary/test_repo/issues"
    res = http_post(url, params.to_json)

    if res.status.to_s =~ /^2\d\d$/
      body = JSON.parse(res.body)

      {
        id:     body["id"],
        number: body["number"],
        url:    body["html_url"]
      }
    end
  end

end
