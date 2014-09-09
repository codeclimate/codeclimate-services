 # encoding: UTF-8

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

    # payloads for test receivers include the weekly quality report.
    send_snapshot_to_slack(CC::Formatters::SnapshotFormatter::Test.new(repo, payload))

    { ok: true, message: "Test message sent" }
  rescue => ex
    { ok: false, message: ex.message }
  end

  def receive_snapshot
    send_snapshot_to_slack(CC::Formatters::SnapshotFormatter::Base.new(repo, payload))
  end

  def receive_coverage
    speak(formatter.format_coverage, hex_color)
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
      fields: [{ value: message }],
      mrkdwn_in: ["fields", "fallback"]
    }]}

    if config.channel
      body[:channel] = config.channel
    end

    http.headers['Content-Type']  = 'application/json'
    http_post(config.webhook_url, body.to_json)
  end

  def send_snapshot_to_slack(payload, sample = false)
    snapshot = SnapshotEventFormatter.new(repo, payload, sample)

    if formatter.alert_constants_payload
      speak(alerts_message(snapshot), RED_HEX)
    end

    if formatter.improved_constants_payload
      speak(improvements_message(snapshot), GREEN_HEX)
    end
  end

  def alert_message(snapshot)
    constants = snapshot.alert_constants_payload

    message = ["Quality alert triggered for *#{repo_identifier}* (<#{compare_url}|Compare>)\n"]

    constants[0..2].each do |constant|
      object_identifier = constant_basename(constant["name"])

      if constant["from"]
        from_rating = from_rating(constant)
        to_rating = to_rating(constant)

        message << "• _#{object_identifier}_ just declined from #{with_article(from_rating, :bold)} to #{with_article(to_rating, :bold)}"
      else
        rating = to_rating(constant)

        message << "• _#{object_identifier}_ was just created and is #{with_article(rating, :bold)} *#{rating}*"
      end
    end

    if constants.size > 3
      remaining = constants.size - 3
      message << "\nAnd <#{details_url}|#{remaining} other #{"change".pluralize(remaining)}>"
    end

    message.join("\n")
  end

  def improvement_message(snapshot)
    constants = snapshot.improved_constants_payload

    message = ["Quality improvements in *#{repo_identifier}* (<#{compare_url}|Compare>)\n"]

    constants[0..2].each do |constant|
      object_identifier = constant_basename(constant["name"])
      from_rating = from_rating(constant)
      to_rating = to_rating(constant)

      message << "• _#{object_identifier}_ just improved from #{with_article(from_rating, :bold)} to #{with_article(to_rating, :bold)}"
    end

    if constants.size > 3
      remaining = constants.size - 3
      message << "\nAnd <#{details_url}|#{remaining} other #{"improvement".pluralize(remaining)}>"
    end

    message.join("\n")
  end
end
end
