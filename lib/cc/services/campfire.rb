class CC::Service::Campfire < CC::Service
  class Config < CC::Service::Config
    attribute :subdomain, String,
      description: "The Campfire subdomain for the account"
    attribute :token, String,
      description: "Your Campfire API auth token"
    attribute :room_id, String,
      description: "Check your campfire URL for a room ID. Usually 6 digits."

    validates :subdomain, presence: true
    validates :room_id, presence: true
    validates :token, presence: true
  end

  self.description = "Send messages to a Campfire chat room"

  def receive_coverage
    message =  "[Code Climate][#{repo_name}]"
    message << " #{emoji} Test coverage has #{changed}"
    message << " to #{covered_percent}% (#{delta})."
    message << " (#{details_url})"

    speak(message)
  end

private

  def speak(line)
    http.headers['Content-Type']  = 'application/json'
    body = { message: { body: line } }

    http.basic_auth(config.token, "X")
    http_post(speak_uri, body.to_json)
  end

  def speak_uri
    subdomain = config.subdomain
    room_id = config.room_id
    "https://#{subdomain}.campfirenow.com/room/#{room_id}/speak.json"
  end

end
