class CC::Service::Flowdock < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, String,
      label: "API Token",
      description: "The API token of the Flow to send notifications to",
      link: "https://www.flowdock.com/account/tokens"
    validates :api_token, presence: true
  end

  BASE_URL = "https://api.flowdock.com/v1"

  def receive_unit
    params = {
      source:       "Code Climate",
      from_address: "notifications@codeclimate.com",
      from_name:    "Code Climate",
      format:       "html",
      subject:      "Subject",
      project:      "Project",
      content:      "Content",
      link:         "https://codeclimate.com"
    }

    url = "#{BASE_URL}/messages/team_inbox/#{config.api_token}"
    http.headers["User-Agent"] = "Code Climate"
    http_post(url, params)
  end
end
