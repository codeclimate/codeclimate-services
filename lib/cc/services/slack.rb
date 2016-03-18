 # encoding: UTF-8

class CC::Service::Slack < CC::Service
  include CC::Service::QualityHelper

  class Config < CC::Service::Config
    attribute :webhook_url, Axiom::Types::String,
      label: "Webhook URL",
      description: "The Slack webhook URL you would like message posted to"

    attribute :channel, Axiom::Types::String,
      description: "The channel to send to (optional). Enter # before the channel name."
  end

  self.description = "Send messages to a Slack channel"

  def receive_test
    # payloads for test receivers include the weekly quality report.
    send_snapshot_to_slack(CC::Formatters::SnapshotFormatter::Sample.new(payload))
    speak(formatter.format_test).merge(
      message: "Test message sent"
    )
  end

  def receive_snapshot
    send_snapshot_to_slack(CC::Formatters::SnapshotFormatter::Base.new(payload))
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
    params = { attachments: [{
      color: color,
      fallback: message,
      fields: [{ value: message }],
      mrkdwn_in: ["fields", "fallback"]
    }]}

    if config.channel
      params[:channel] = config.channel
    end

    http.headers['Content-Type']  = 'application/json'
    url = config.webhook_url

    service_post(url, params.to_json) do |response|
      {
        ok: response.body == "ok",
        message: response.body
      }
    end
  end

  def send_snapshot_to_slack(snapshot)
    if snapshot.alert_constants_payload
      @response = speak(alerts_message(snapshot.alert_constants_payload), RED_HEX)
    end

    if snapshot.improved_constants_payload
      @response = speak(improvements_message(snapshot.improved_constants_payload), GREEN_HEX)
    end

    @response || { ok: false, ignored: true, message: "No changes in snapshot" }
  end

  def alerts_message(constants_payload)
    constants = constants_payload["constants"]
    message = ["Quality alert triggered for *#{repo_name}* (<#{compare_url}|Compare>)\n"]

    constants[0..2].each do |constant|
      object_identifier = constant_basename(constant["name"])

      if constant["from"]
        from_rating = constant["from"]["rating"]
        to_rating   = constant["to"]["rating"]

        message << "• _#{object_identifier}_ just declined from #{with_article(from_rating, :bold)} to #{with_article(to_rating, :bold)}"
      else
        rating = constant["to"]["rating"]

        message << "• _#{object_identifier}_ was just created and is #{with_article(rating, :bold)}"
      end
    end

    if constants.size > 3
      remaining = constants.size - 3
      message << "\nAnd <#{details_url}|#{remaining} other #{"change".pluralize(remaining)}>"
    end

    message.join("\n")
  end

  def improvements_message(constants_payload)
    constants = constants_payload["constants"]
    message = ["Quality improvements in *#{repo_name}* (<#{compare_url}|Compare>)\n"]

    constants[0..2].each do |constant|
      object_identifier = constant_basename(constant["name"])
      from_rating = constant["from"]["rating"]
      to_rating   = constant["to"]["rating"]

      message << "• _#{object_identifier}_ just improved from #{with_article(from_rating, :bold)} to #{with_article(to_rating, :bold)}"
    end

    if constants.size > 3
      remaining = constants.size - 3
      message << "\nAnd <#{details_url}|#{remaining} other #{"improvement".pluralize(remaining)}>"
    end

    message.join("\n")
  end
end
