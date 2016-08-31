class CC::Service::BodyExtractingResponseFormatter < CC::Service::GenericResponseFormatter
  def initialize(attrs)
    @block = lambda do |raw_response, formatted_response|
      body = JSON.parse(raw_response.body)
      attrs.each do |formatted_key, raw_key|
        value =
          if raw_key.respond_to?(:call)
            raw_key.call(body)
          else
            body[raw_key]
          end
        formatted_response[formatted_key] = value
      end
      formatted_response
    end
  end
end
