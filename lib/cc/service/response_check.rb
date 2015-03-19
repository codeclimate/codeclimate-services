class CC::Service
  class HTTPError < StandardError
    attr_reader :response_body, :status, :params, :endpoint_url
    attr_accessor :user_message

    def initialize(message, env)
      @response_body = env[:body]
      @status        = env[:status]
      @params        = env[:params]
      @endpoint_url  = env[:url].to_s

      super(message)
    end
  end

  class ResponseCheck < Faraday::Response::Middleware
    ErrorStatuses = 400...600

    def on_complete(env)
      if ErrorStatuses === env[:status]
        message = error_message(env) ||
          "API request unsuccessful (#{env[:status]})"

        raise HTTPError.new(message, env)
      end
    end

  private

    def error_message(env)
      # We only handle Jira (or responses which look like Jira's). We will add
      # more logic here over time to account for other service's typical error
      # responses as we see them.
      if env[:response_headers]["content-type"] =~ /application\/json/
        errors = JSON.parse(env[:body])["errors"]
        errors.is_a?(Hash) && errors.values.map(&:capitalize).join(", ")
      end
    rescue JSON::ParserError
    end

  end
end
