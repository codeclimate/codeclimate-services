class CC::Service::Slack < CC::Service
  class Config < CC::Service::Config
    attribute :url, String,
      label: "Webhook URL",
      description: "The Slack webhook URL you would like message posted to"

    attribute :channel, String,
      description: "The channel to send to (optional)"
  end

  self.description = "Send messages to a Slack channel"

  def receive_test
    speak(formatter.format_test)
  end

  def receive_coverage
    speak(formatter.format_coverage, icon_emoji: emoji)
  end

  def receive_quality
    speak(formatter.format_quality, icon_emoji: emoji)
  end

  def receive_vulnerability
    speak(formatter.format_vulnerability)
  end

  private

  def formatter
    CC::Formatters::LinkedFormatter.new(self, prefix: nil, link_style: :wiki)
  end

  def speak(message, options = {})
    body = {
      text: message,
      username: "Code Climate"
    }.merge(options)

    if config.channel
      body[:channel] = config.channel
    end

    http_post(config.url, body)
  end
end
