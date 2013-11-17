class CC::Service::Campfire < CC::Service
  class Config < CC::Service::Config
    attribute :subdomain, String
    attribute :room_id, String
    attribute :token, String

    validates :subdomain, presence: true
    validates :room_id, presence: true
    validates :token, presence: true
  end

  def receive_coverage
    speak("Coverage: #{coverage}")
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
