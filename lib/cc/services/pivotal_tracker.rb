class CC::Service::PivotalTracker < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, String,
      description: "Your Pivotal Tracker API Token, from your profile page"

    attribute :project_id, String,
      description: "Your Pivotal Tracker project ID"

    attribute :labels, String,
      label: "Labels (comma separated)",
      description: "Comma separated list of labels to apply to the story"

    validates :api_token, presence: true
    validates :project_id, presence: true
  end

  self.title = "Pivotal Tracker"
  self.issue_tracker = true

  BASE_URL = "https://www.pivotaltracker.com/services/v3"

  def receive_unit
    params = {
      "story[name]"           => "name",
      "story[story_type]"     => "chore",
      "story[description]"    => "description"
    }

    if config.labels.present?
      params["story[labels]"] = config.labels.strip
    end

    http.headers["X-TrackerToken"] = config.api_token
    url = "#{BASE_URL}/projects/#{config.project_id}/stories"
    res = http_post(url, params)

    if res.status.to_s =~ /^2\d\d$/
      parse_story(res)
    end
  end

private

  def parse_story(resp)
    body = Nokogiri::XML(resp.body)

    {
      id:   (body / "story/id").text,
      url:  (body / "story/url").text
    }
  end

end
