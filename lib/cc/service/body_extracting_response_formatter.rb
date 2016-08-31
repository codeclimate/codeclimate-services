module CC
  class Service
    class BodyExtractingResponseFormatter < GenericResponseFormatter
      def initialize(attrs)
        @block = custom_behavior(attrs)
      end

      private

      def custom_behavior(attrs)
        lambda do |raw_response, formatted_response|
          body = JSON.parse(raw_response.body)
          attrs.each do |formatted_key, raw_key|
            formatted_response[formatted_key] = extract(raw_key, body)
          end
          formatted_response
        end
      end

      def extract(raw_key, body)
        if raw_key.respond_to?(:call)
          raw_key.call(body)
        else
          body[raw_key]
        end
      end
    end
  end
end
