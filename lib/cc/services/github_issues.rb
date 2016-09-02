class CC::Service::GitHubIssues < CC::Service
  class Config < CC::Service::Config
    attribute :oauth_token, Axiom::Types::String,
      label: "OAuth Token",
      description: "A personal OAuth token with permissions for the repo"
    attribute :project, Axiom::Types::String,
      label: "Project",
      description: "Project name on GitHub (e.g 'thoughtbot/paperclip')"
    attribute :labels, Axiom::Types::String,
      label: "Labels (comma separated)",
      description: "Comma separated list of labels to apply to the issue"
    attribute :base_url, Axiom::Types::String,
      label: "Github API Base URL",
      description: "Base URL for the Github API",
      default: "https://api.github.com"

    validates :oauth_token, presence: true
  end

  self.title = "GitHub Issues"
  self.description = "Open issues on GitHub"
  self.issue_tracker = true

  def receive_test
    result = create_issue("Test ticket from Code Climate", "")
    result.merge(
      message: "Issue <a href='#{result[:url]}'>##{result[:number]}</a> created.",
    )
  rescue CC::Service::HTTPError => e
    body = JSON.parse(e.response_body)
    e.user_message = body["message"]
    raise e
  end

  def receive_quality
    create_issue(quality_title, details_url)
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)

    create_issue(
      formatter.format_vulnerability_title,
      formatter.format_vulnerability_body,
    )
  end

  def receive_issue
    title = %(Fix "#{issue["check_name"]}" issue in #{constant_name})

    body = [issue["description"], details_url].join("\n\n")

    create_issue(title, body)
  end

  private

  def create_issue(title, issue_body)
    params = { title: title, body: issue_body }

    if config.labels.present?
      params[:labels] = config.labels.split(",").map(&:strip).reject(&:blank?).compact
    end

    http.headers["Content-Type"] = "application/json"
    http.headers["Authorization"] = "token #{config.oauth_token}"
    http.headers["User-Agent"] = "Code Climate"

    url = "#{config.base_url}/repos/#{config.project}/issues"
    service_post_with_redirects(url, params.to_json) do |response|
      body = JSON.parse(response.body)
      {
        id: body["id"],
        number: body["number"],
        url: body["html_url"],
      }
    end
  end
end
