module CC
  class Service
    require "cc/service/config"
    require "cc/service/http"
    require "cc/service/helper"
    require "cc/service/formatter"
    require "cc/service/invocation"

    dir = File.expand_path '../helpers', __FILE__
    Dir["#{dir}/*_helper.rb"].each do |helper|
      require helper
    end

    dir = File.expand_path '../formatters', __FILE__
    Dir["#{dir}/*_formatter.rb"].each do |formatter|
      require formatter
    end

    def self.load_services
      path = File.expand_path("../services/**/*.rb", __FILE__)
      Dir[path].each { |lib| require(lib) }
    end

    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)

    include HTTP
    include Helper

    attr_reader :event, :config, :payload

    ALL_EVENTS = %w[test unit coverage quality vulnerability]

    # Tracks the defined services.
    def self.services
      @services ||= []
    end

    def self.inherited(svc)
      Service.services << svc
      super
    end

    def self.by_slug(slug)
      services.detect { |s| s.slug == slug }
    end

    class << self
      attr_writer :title
      attr_accessor :description
      attr_accessor :issue_tracker
    end

    def self.title
      @title ||= begin
        hook = name.dup
        hook.sub! /.*:/, ''
        hook
      end
    end

    def self.slug
      @slug ||= begin
        hook = name.dup
        hook.downcase!
        hook.sub! /.*:/, ''
        hook
      end
    end

    def initialize(config, payload)
      @payload = payload.stringify_keys
      @config  = create_config(config)
      @event   = @payload["name"].to_s

      load_helper
      validate_event
    end

    def receive
      if respond_to?(:receive_event)
        receive_event
      else
        public_send("receive_#{event}")
      end
    end

    private

    def load_helper
      helper_name = "#{event.classify}Helper"

      if Service.const_defined?(helper_name)
        @helper = Service.const_get(helper_name)
        extend @helper
      end
    end

    def validate_event
      unless ALL_EVENTS.include?(event)
        raise ArgumentError.new("Invalid event: #{event}")
      end
    end

    def create_config(config)
      config_class.new(config).tap do |c|
        unless c.valid?
          raise ConfigurationError, "Invalid config: #{config.inspect}"
        end
      end
    end

    def config_class
      if defined?("#{self.class.name}::Config")
        "#{self.class.name}::Config".constantize
      else
        Config
      end
    end

  end
end
