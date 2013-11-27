module CC
  class Service
    require "cc/service/config"
    require "cc/service/http"

    dir = File.expand_path '../service', __FILE__
    Dir["#{dir}/events/*.rb"].each do |helper|
      require helper
    end

    def self.load_services
      path = File.expand_path("../services/**/*.rb", __FILE__)
      Dir[path].each { |lib| require(lib) }
    end

    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)

    include HTTP

    cattr_accessor :issue_tracker
    attr_reader :event, :config, :payload

    ALL_EVENTS = %w[unit coverage]

    def self.receive(event, config, payload)
      new(event, config, payload).receive
    end

    # Tracks the defined services.
    def self.services
      @services ||= []
    end

    def self.inherited(svc)
      Service.services << svc
      super
    end

    def initialize(event, config, payload)
      validate_event(event)

      helper_name = "#{event.to_s.classify}Helpers"
      if Service.const_defined?(helper_name)
        @helper = Service.const_get(helper_name)
        extend @helper
      end

      @event    = event.to_s
      @payload  = payload.stringify_keys
      @config   = create_config(config)
    end

    def receive
      validate_event(event)

      if respond_to?(:receive_event)
        receive_event
      else
        send("receive_#{@event}")
      end
    end

    def validate_event(event)
      unless ALL_EVENTS.include?(event.to_s)
        raise ArgumentError.new("Invalid event: #{event}")
      end
    end

    def create_config(config)
      config_class = if defined?("#{self.class.name}::Config")
        "#{self.class.name}::Config".constantize
      else
        Config
      end

      config_class.new(config).tap do |c|
        unless c.valid?
          raise ConfigurationError, "Invalid config: #{config.inspect}"
        end
      end
    end

  end
end
