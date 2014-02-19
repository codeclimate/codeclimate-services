class CC::Service::Flowdock < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, String,
      label: "API Token",
      description: "The API token of the Flow to send notifications to",
      link: "https://www.flowdock.com/account/tokens"
    validates :api_token, presence: true
  end

  BASE_URL = "https://api.flowdock.com/v1"

  self.description = "Send messages to a Flowdock inbox"

  def receive_test
    notify("Test", repo_name, "This is a test of the Flowdock service hook")
  end

  def receive_coverage
    message = "<a href=\"#{details_url}\">Test coverage</a>"
    message << " has #{changed} to #{covered_percent}% (#{delta})"

    notify("Coverage", repo_name, message)
  end

  def receive_quality
    message = "<a href=\"#{details_url}\">#{constant_name}</a>"
    message << " has #{changed} from #{previous_rating} to #{rating}"

    notify("Quality", repo_name, message)
  end

  def receive_vulnerability
    notify("Vulnerability", repo_name, "#{new_issues_found(true)}.")
  end

  private

  def notify(subject, project, content)
    params = {
      source:       "Code Climate",
      from_address: "notifications@codeclimate.com",
      from_name:    "Code Climate",
      format:       "html",
      subject:      subject,
      project:      project,
      content:      content,
      link:         "https://codeclimate.com"
    }

    url = "#{BASE_URL}/messages/team_inbox/#{config.api_token}"
    http.headers["User-Agent"] = "Code Climate"
    http_post(url, params)
  end
end
