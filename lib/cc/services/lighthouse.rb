class CC::Service::Lighthouse < CC::Service
  class Config < CC::Service::Config
    attribute :subdomain, String,
      description: "Your Lighthouse subdomain"

    attribute :api_token, String,
      label: "API Token",
      description: "Your Lighthouse API Key (http://help.lighthouseapp.com/kb/api/how-do-i-get-an-api-token)"

    attribute :project_id, String,
      description: "Your Lighthouse project ID. You can find this from the URL to your Lighthouse project."

    attribute :tags, String,
      description: "Which tags to add to tickets, comma delimited"

    validates :subdomain, presence: true
    validates :api_token, presence: true
    validates :project_id, presence: true
  end

  self.title = "Lighthouse"
  self.issue_tracker = true

  def receive_quality
    title = "Refactor #{constant_name} from #{rating} on Code Climate"
    create_ticket(title, details_url)
  end

private

  def create_ticket(title, body)
    params = { ticket: { title: title, body: body } }

    if config.tags.present?
      params[:ticket][:tags] = config.tags.strip
    end

    parse_api_response(post_to_api(params))
  end

  def post_to_api(params)
    http.headers["X-LighthouseToken"] = config.api_token
    http.headers["Content-Type"] = "application/json"

    base_url = "https://#{config.subdomain}.lighthouseapp.com"
    url = "#{base_url}/projects/#{config.project_id}/tickets.json"

    http_post(url, params.to_json)
  end

  def parse_api_response(response)
    return unless response.status.to_s =~ /^2\d\d$/

    body = JSON.parse(response.body)

    {
      id:  body["ticket"]["number"],
      url: body["ticket"]["url"]
    }
  end

end
