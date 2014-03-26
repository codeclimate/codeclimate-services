class CC::Service::JSONMiddleware < Faraday::Middleware
  def call(env)
    env[:request_headers].merge!(
      "Content-Type" => "application/json"
    )

    env[:body] = (env[:body] || {}).to_json

    @app.call(env).on_complete do
      env[:body] = parse_json(env[:body])
    end
  end

  def parse_json(string)
    JSON.parse(string)
  rescue JSON::ParserError
    string # return unparsable responses as-is
  end
end
