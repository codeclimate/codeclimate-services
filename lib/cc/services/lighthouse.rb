class CC::Service::Lighthouse < CC::Service
  class Config < CC::Service::Config
    attribute :subdomain, String
    attribute :api_token, String
    attribute :project_id, String
    attribute :tags, String

    validates :subdomain, presence: true
    validates :api_token, presence: true
    validates :project_id, presence: true
  end

  self.issue_tracker = true

  def receive_unit
    params = {
      ticket: {
        title: "Title",
        body: "Body",
      }
    }

    if config.tags.present?
      params[:ticket][:tags] = config.tags.strip
    end

    http.headers["X-LighthouseToken"] = config.api_token
    http.headers["Content-Type"] = "application/json"

    base_url = "https://#{config.subdomain}.lighthouseapp.com"
    url = "#{base_url}/projects/#{config.project_id}/tickets.json"

    res = http_post(url, params.to_json)

    if res.status.to_s =~ /^2\d\d$/
      body = JSON.parse(res.body)

      {
        id:   body["ticket"]["number"],
        url:  body["ticket"]["url"]
      }
    end
  end

end
