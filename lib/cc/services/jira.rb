require "base64"

class CC::Service::Jira < CC::Service
  class Config < CC::Service::Config
    attribute :domain, Axiom::Types::String,
      description: "Your JIRA host domain (e.g. yourjira.com:PORT, please exclude https://)"

    attribute :username, Axiom::Types::String,
      description: "Must exactly match the 'username' that appears on your JIRA profile page."

    attribute :password, Axiom::Types::Password,
      label: "JIRA password",
      description: "Your JIRA password"

    attribute :project_id, Axiom::Types::String,
      description: "Your JIRA project ID number (located in your JIRA admin panel). Project must contain only the default required fields."

    attribute :issue_type, Axiom::Types::String,
      description: "The type of Issue to be created.",
      default: "Task"

    attribute :labels, Axiom::Types::String,
      description: "Which labels to add to issues, comma delimited"

    validates :domain, presence: true
    validates :username, presence: true
    validates :password, presence: true
    validates :project_id, presence: true
  end

  self.title = "JIRA"
  self.description = "Create tickets in JIRA"
  self.issue_tracker = true

  def receive_test
    result = create_ticket("Test ticket from Code Climate", "Test ticket from Code Climate")
    result.merge(
      message: "Ticket <a href='#{result[:url]}'>#{result[:id]}</a> created.",
    )
  end

  def receive_quality
    create_ticket(quality_title, details_url)
  end

  def receive_issue
    title = %(Fix "#{issue["check_name"]}" issue in #{constant_name})

    body = [issue["description"], details_url].join("\n\n")

    create_ticket(title, body)
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)

    create_ticket(
      formatter.format_vulnerability_title,
      formatter.format_vulnerability_body,
    )
  end

  private

  def create_ticket(title, ticket_body)
    params = {
      fields:
        {
          project: { id: config.project_id },
          summary: title,
          description: ticket_body,
          issuetype: { name: config.issue_type },
        },
    }

    if config.labels.present?
      params[:fields][:labels] = config.labels.split(",")
    end

    http.headers["Content-Type"] = "application/json"
    http.basic_auth(config.username, config.password)

    url = "https://#{config.domain}/rest/api/2/issue/"

    formatter = BodyExtractingResponseFormatter.new(
      id: "id",
      key: "key",
      url: -> (body) { "https://#{config.domain}/browse/#{body["key"]}" },
    )
    service_post(url, params.to_json, formatter)
  end
end
