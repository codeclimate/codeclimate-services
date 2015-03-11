class CC::Service::Asana < CC::Service
  class Config < CC::Service::Config
    attribute :api_key, String, label: "API key"

    attribute :workspace_id, String, label: "Workspace ID"

    attribute :project_id, String, label: "Project ID",
      description: "(optional)"

    attribute :assignee, String, label: "Assignee",
      description: "Assignee email address (optional)"

    validates :api_key, presence: true
    validates :workspace_id, presence: true
  end

  ENDPOINT = "https://app.asana.com/api/1.0/tasks"

  self.title = "Asana"
  self.description = "Create tasks in Asana"
  self.issue_tracker = true

  def receive_test
    result = create_task("Test task from Code Climate")
    result.merge(
      message: "Ticket <a href='#{result[:url]}'>#{result[:id]}</a> created."
    )
  rescue CC::Service::HTTPError => ex
    body = JSON.parse(ex.response_body)
    ex.user_message = body["errors"].map{|e| e["message"] }.join(" ")
    raise ex
  end


  def receive_quality
    title = "Refactor #{constant_name} from #{rating} on Code Climate"

    create_task("#{title} - #{details_url}")
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)
    title     = formatter.format_vulnerability_title

    create_task("#{title} - #{details_url}")
  end

private

  def create_task(name)
    params = generate_params(name)
    authenticate_http
    http.headers["Content-Type"] = "application/json"
    service_post(ENDPOINT, params.to_json) do |response|
      body = JSON.parse(response.body)
      id = body['data']['id']
      url = "https://app.asana.com/0/#{config.workspace_id}/#{id}"
      { id: id, url: url }
    end
  end

  def generate_params(name)
    params = {
      data: { workspace: config.workspace_id, name: name }
    }

    if config.project_id.present?
      # Note this is undocumented, found via trial & error
      params[:data][:projects] = [config.project_id]
    end

    if config.assignee.present?
      params[:data][:assignee] = config.assignee
    end

    params
  end

  def authenticate_http
    http.basic_auth(config.api_key, "")
  end

end
