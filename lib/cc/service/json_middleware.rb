class CC::Service::JSONMiddleware < Faraday::Middleware
  def call(env)
    env[:request_headers].merge!(
      "Content-Type" => "application/json"
    )

    env[:body] = (env[:body] || {}).to_json

    @app.call(env).on_complete do
      env[:body] = JSON.parse(env[:body])
    end
  end
end
