module CC
  class Service
    def self.load_services
      path = File.expand_path("../services/**/*.rb", __FILE__)
      Dir[path].each { |lib| require(lib) }
    end

    ConfigurationError = Class.new(StandardError)

    attr_reader :event, :config, :payload

    ALL_EVENTS = %w[coverage]

    def self.default_http_options
      @@default_http_options ||= {
        :adapter => :net_http,
        :request => { :timeout => 10, :open_timeout => 5 },
        :ssl => { :verify_depth => 5 },
        :headers => {}
      }
    end

    def self.receive(event, config, payload)
      new(event, config, payload).recieve
    end

    def initialize(event, config, payload)
      validate_event(event)
      @event    = event
      @config   = config.stringify_keys
      @payload  = payload
    end

    def receive
      validate_event(event)

      if respond_to?(:receive_event)
        receive_event
      else
        send("receive_#{@event}")
      end
    end

    def http_post(url = nil, body = nil, headers = nil)
      block = Proc.new if block_given?
      http_method :post, url, body, headers, &block
    end

    def http_method(method, url = nil, body = nil, headers = nil)
      block = Proc.new if block_given?

      http.send(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        block.call req if block
      end
    end

    def http(options = {})
      @http ||= begin
        config = self.class.default_http_options
        config.each do |key, sub_options|
          next if key == :adapter
          sub_hash = options[key] ||= {}
          sub_options.each do |sub_key, sub_value|
            sub_hash[sub_key] ||= sub_value
          end
        end
        options[:ssl][:ca_file] ||= ca_file

        Faraday.new(options) do |b|
          b.request(:url_encoded)
          b.adapter(*Array(options[:adapter] || config[:adapter]))
        end
      end
    end

    # Gets the path to the SSL Certificate Authority certs.  These were taken
    # from: http://curl.haxx.se/ca/cacert.pem
    #
    # Returns a String path.
    def ca_file
      @ca_file ||= File.expand_path('../../config/cacert.pem', __FILE__)
    end

    # Grabs a sanitized configuration value.
    def config_value(key)
      value = config[key.to_s].to_s
      value.strip!
      value
    end

    # Grabs a sanitized configuration value and ensures it is set.
    def required_config_value(key)
      if (value = config_value(key)).empty?
        raise ConfigurationError, "#{key.inspect} is empty"
      end

      value
    end

    def validate_event(event)
      unless ALL_EVENTS.include?(event.to_s)
        raise ArgumentError.new("Invalid event: #{event}")
      end
    end
  end
end
