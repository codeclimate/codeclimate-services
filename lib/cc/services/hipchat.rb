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
    speak("[#{repo_name}] This is a test of the HipChat service hook", "green")
  end

  def receive_coverage
    message = "[#{repo_name}] <a href=\"#{details_url}\">Test coverage</a>"
    message << " has #{changed} to #{covered_percent}% (#{delta})"

    if compare_url
      message << " (<a href=\"#{compare_url}\">Compare</a>)"
    end

    speak(message, color)
  end

  def receive_quality
    message = "[#{repo_name}] <a href=\"#{details_url}\">#{constant_name}</a>"
    message << " has #{changed} from #{previous_rating} to #{rating}"

    if compare_url
      message << " (<a href=\"#{compare_url}\">Compare</a>)"
    end

    speak(message, color)
  end

  private

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
