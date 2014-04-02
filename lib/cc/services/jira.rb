require 'base64'

class CC::Service::Jira < CC::Service
  class Config < CC::Service::Config
    attribute :domain, String,
      description: "Your JIRA host domain (e.g. yourjira.com:PORT)"

    attribute :username, String,
      description: "Your JIRA username"

    attribute :password, String,
      label: "JIRA password",
      description: "Your JIRA password"

    attribute :project_id, String,
      description: "Your JIRA project ID."

    attribute :labels, String,
      description: "Which labels to add to issues, comma delimited"

    validates :domain, presence: true
    validates :username, presence: true
    validates :password, presence: true
    validates :project_id, presence: true
  end

  self.title = "Jira"
  self.description = "Create tickets in Jira"
  self.issue_tracker = true

  def receive_test
    create_ticket("Test ticket from Code Climate", "")
  end

  def receive_quality
    title = "Refactor #{constant_name} from #{rating} on Code Climate"

    create_ticket(title, details_url)
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)

    create_ticket(
      formatter.format_vulnerability_title,
      formatter.format_vulnerability_body
    )
  end

private

  def create_ticket(title, ticket_body)
    params = {
      fields:
        {
          project: { id: config.project_id },
          summary: title,
          description: ticket_body
        }
    }

    if config.labels.present?
      params[:fields][:labels] = config.labels.strip
    end

    http.headers["Authorization"] = "Basic #{encoded_username_password}"
    http.headers["Content-Type"] = "application/json"

    url = "https://#{config.domain}/rest/api/2/issue/"

    res = http_post(url, params.to_json)

    body = JSON.parse(res.body)

    {
      id:  body["id"],
      url: body["self"]
    }
  end

  def encoded_username_password
    Base64.encode64("#{config.username}:#{config.password}")
  end

end
