class CC::Service::HipChat < CC::Service
  class Config < CC::Service::Config
    attribute :auth_token, String,
      description: "Your HipChat API auth token"

    attribute :room_id, String,
      description: "The ID or name of the HipChat chat room to send notifications to"

    attribute :notify, Boolean, default: false,
      description: "Should we trigger a notification for people in the room?"

    validates :auth_token, presence: true
    validates :room_id, presence: true
  end

  BASE_URL = "https://api.hipchat.com/v1"

  self.description = "Send messages to a HipChat chat room"

  def receive_test
    speak(formatter.format_test, "green")
  end

  def receive_coverage
    speak(formatter.format_coverage, color)
  end

  def receive_quality
    speak(formatter.format_quality, color)
  end

  def receive_vulnerability
    speak(formatter.format_vulnerability, "red")
  end

  private

  def formatter
    CC::Formatters::HtmlFormatter.new(self, prefix: "")
  end

  def speak(message, color)
    http_post("#{BASE_URL}/rooms/message", {
      from:       "Code Climate",
      message:    message,
      auth_token: config.auth_token,
      room_id:    config.room_id,
      notify:     !!config.notify,
      color:      color
    })
  end

end
