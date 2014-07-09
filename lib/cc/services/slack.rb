class CC::Service::Slack < CC::Service
  class Config < CC::Service::Config
    attribute :webhook_url, String,
      label: "Webhook URL",
      description: "The Slack webhook URL you would like message posted to"

    attribute :channel, String,
      description: "The channel to send to (optional)"
  end

  self.description = "Send messages to a Slack channel"

  def receive_test
    speak(formatter.format_test)

    { ok: true, message: "Test message sent" }
  rescue => ex
    { ok: false, message: ex.message }
  end

  def receive_coverage
    speak(formatter.format_coverage, hex_color)
  end

  def receive_quality
    speak(formatter.format_quality, hex_color)
  end

  def receive_vulnerability
    speak(formatter.format_vulnerability)
  end

  private

  def formatter
    CC::Formatters::LinkedFormatter.new(self, prefix: nil, link_style: :wiki)
  end

  def speak(message, color = nil)
    body = { attachments: [{
      color: color,
      fallback: message,
      fields: [{ value: message }]
    }]}

    if config.channel
      body[:channel] = config.channel
    end

    http.headers['Content-Type']  = 'application/json'
    http_post(config.webhook_url, body.to_json)
  end
end
