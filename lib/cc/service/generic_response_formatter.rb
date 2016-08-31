module CC
  class Service
    class GenericResponseFormatter
      def initialize(http_prefix: nil, &block)
        @http_prefix = http_prefix
        @block = block || noop
      end

      def post(url, body, response)
        block.call(
          response,
          ok: response.success?,
          "#{http_prefix}params".to_sym => body.as_json,
          "#{http_prefix}endpoint_url".to_sym => url,
          "#{http_prefix}status".to_sym => response.status,
          message: "Success",
        )
      end

      private

      attr_reader :http_prefix, :block

      def noop
        ->(_raw_response, formatted_response) { formatted_response }
      end
    end
  end
end
