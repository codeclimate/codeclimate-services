class CC::Service::HipChat < CC::Service
  class Config < CC::Service::Config
    attribute :auth_token, String
    attribute :room_id, String
    attribute :notify, Boolean

    validates :auth_token, presence: true
    validates :room_id, presence: true
  end

  BASE_URL = "https://api.hipchat.com/v1"

  def receive_coverage
    details = {
      coverage: payload["coverage"]
    }

    speak(render_coverage(details), color: "yellow")
  end

private

  def speak(message, options)
    payload = {
      from:       "Code Climate",
      message:    message,
      auth_token: config.auth_token,
      room_id:    config.room_id,
      notify:     !!config.notify
    }.merge(options)

    http_post("#{BASE_URL}/rooms/message", payload)
  end

  def render_coverage(details)
    Liquid::Template.parse(<<-EOF.strip).render(details.stringify_keys)
      <b>Coverage:</b> {{coverage}}
    EOF
  end

end
