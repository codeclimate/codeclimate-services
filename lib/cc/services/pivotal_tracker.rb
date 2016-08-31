class CC::Service::PivotalTracker < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, Axiom::Types::String,
      description: "Your Pivotal Tracker API Token, from your profile page"

    attribute :project_id, Axiom::Types::String,
      description: "Your Pivotal Tracker project ID"

    attribute :labels, Axiom::Types::String,
      label: "Labels (comma separated)",
      description: "Comma separated list of labels to apply to the story"

    validates :api_token, presence: true
    validates :project_id, presence: true
  end

  self.title = "Pivotal Tracker"
  self.description = "Create stories on Pivotal Tracker"
  self.issue_tracker = true

  BASE_URL = "https://www.pivotaltracker.com/services/v3".freeze

  def receive_test
    result = create_story("Test ticket from Code Climate", "")
    result.merge(
      message: "Ticket <a href='#{result[:url]}'>#{result[:id]}</a> created.",
    )
  end

  def receive_quality
    create_story(quality_title, details_url)
  end

  def receive_issue
    title = %(Fix "#{issue["check_name"]}" issue in #{constant_name})

    body = [issue["description"], details_url].join("\n\n")

    create_story(title, body)
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)

    create_story(
      formatter.format_vulnerability_title,
      formatter.format_vulnerability_body,
    )
  end

  private

  def create_story(name, description)
    params = {
      "story[name]"        => name,
      "story[story_type]"  => "chore",
      "story[description]" => description,
    }

    if config.labels.present?
      params["story[labels]"] = config.labels.strip
    end

    http.headers["X-TrackerToken"] = config.api_token
    url = "#{BASE_URL}/projects/#{config.project_id}/stories"

    formatter = GenericResponseFormatter.new do |raw_response, formatted_response|
      body = Nokogiri::XML(raw_response.body)
      formatted_response.merge(
        id: (body / "story/id").text,
        url: (body / "story/url").text,
      )
    end
    service_post(url, params, formatter)
  end
end
