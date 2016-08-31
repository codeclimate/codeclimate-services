class CC::Service::Flowdock < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, Axiom::Types::String,
      label: "API Token",
      description: "The API token of the Flow to send notifications to",
      link: "https://www.flowdock.com/account/tokens"
    validates :api_token, presence: true
  end

  BASE_URL = "https://api.flowdock.com/v1".freeze
  INVALID_PROJECT_CHARACTERS = /[^0-9a-z\-_ ]+/i

  self.description = "Send messages to a Flowdock inbox"

  def receive_test
    notify("Test", repo_name, formatter.format_test).merge(
      message: "Test message sent",
    )
  end

  def receive_coverage
    notify("Coverage", repo_name, formatter.format_coverage)
  end

  def receive_quality
    notify("Quality", repo_name, formatter.format_quality)
  end

  def receive_vulnerability
    notify("Vulnerability", repo_name, formatter.format_vulnerability)
  end

  private

  def formatter
    CC::Formatters::LinkedFormatter.new(
      self,
      prefix: "",
      prefix_with_repo: false,
      link_style: :html,
    )
  end

  def notify(subject, project, content)
    params = {
      source:       "Code Climate",
      from_address: "hello@codeclimate.com",
      from_name:    "Code Climate",
      format:       "html",
      subject:      subject,
      project:      project.gsub(INVALID_PROJECT_CHARACTERS, ""),
      content:      content,
      link:         "https://codeclimate.com",
    }

    url = "#{BASE_URL}/messages/team_inbox/#{config.api_token}"
    http.headers["User-Agent"] = "Code Climate"

    service_post(url, params)
  end
end
