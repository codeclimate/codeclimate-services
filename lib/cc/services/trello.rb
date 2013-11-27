class CC::Service::Trello < CC::Service
  class Config < CC::Service::Config
    attribute :application_key, String
    attribute :member_token, String
    attribute :board_id, String
    attribute :list_name, String
    attribute :labels, String

    validates :application_key, presence: true
    validates :member_token, presence: true
    validates :board_id, presence: true
    validates :list_name, presence: true
  end

  self.issue_tracker = true

  BASE_URL = "https://api.trello.com/1"

  def receive_unit
    list_id = load_list_id

    params = {
      key:    config.application_key,
      token:  config.member_token,
      idList: list_id,
      name:   "Name",
      due:    nil,
      desc:   "Description"
    }

    if config.labels.present?
      params[:labels] = config.labels.split(",").reject(&:blank?).compact
    end

    res = http_post("#{BASE_URL}/cards", params)

    if res.status.to_s =~ /^2\d\d$/
      body = JSON.parse(res.body)

      {
        id:   body["id"],
        url:  body["url"]
      }
    end
  end

private

  def load_list_id
    res = http_get("#{BASE_URL}/boards/#{config.board_id}/lists", key: config.application_key, token: config.member_token)

    if res.status.to_s =~ /^2\d\d$/
      body = JSON.parse(res.body)
      list = body.detect { |l| l["name"] == config.list_name }
      list ? list["id"] : nil
    end
  end

end
