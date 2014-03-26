class CC::Service::XMLMiddleware < Faraday::Middleware
  def call(env)
    @app.call(env).on_complete do
      env[:body] = Nokogiri::XML(env[:body])
    end
  end
end
