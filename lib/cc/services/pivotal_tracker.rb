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
  self.custom_middleware = XMLMiddleware

  BASE_URL = "https://www.pivotaltracker.com/services/v3"

  def receive_quality
    params = {
      "story[name]" => "Refactor #{constant_name} from #{rating} on Code Climate",
      "story[story_type]" => "chore",
      "story[description]" => details_url,
    }

    if config.labels.present?
      params["story[labels]"] = config.labels.strip
    end

    http.headers["X-TrackerToken"] = config.api_token
    res = http.post("#{BASE_URL}/projects/#{config.project_id}/stories", params)

    {
      id: (res.body / "story/id").text,
      url: (res.body / "story/url").text
    }
  end

end
