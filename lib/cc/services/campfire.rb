class CC::Service::Campfire < CC::Service

  def receive_coverage
    http.headers['Content-Type']  = 'application/json'
    body = { message: { body: "Coverage: #{payload["coverage"]}" } }

    http.basic_auth(required_config_value(:token), "X")
    http_post(speak_uri, body.to_json)
  end

private

  def speak_uri
    subdomain = required_config_value(:subdomain)
    room_id = required_config_value(:room_id)
    "https://#{subdomain}.campfirenow.com/room/#{room_id}/speak.json"
  end

end
