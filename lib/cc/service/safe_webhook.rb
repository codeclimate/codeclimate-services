require "ipaddr"
require "uri"

require "cc/fixed_resolv"

module CC
  class Service
    class SafeWebhook
      InternalWebhookError = Class.new(StandardError)

      PRIVATE_ADDRESS_SUBNETS = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16"),
        IPAddr.new("fd00::/8"),
        IPAddr.new("127.0.0.1"),
        IPAddr.new("0:0:0:0:0:0:0:1"),
      ].freeze

      def self.ensure_safe!(url)
        instance = new(url)
        instance.ensure_safe!
      end

      def self.getaddress(host)
        @dns ||= Resolv::DNS.new
        @dns.getaddress(host)
      end

      def self.setaddress(host, address)
        @fixed_resolv ||= CC::FixedResolv.enable!
        @fixed_resolv.setaddress(host, address)
      end

      def initialize(url)
        @url = url
      end

      def ensure_safe!
        uri = URI.parse(url)

        if !allow_internal_webhooks? && internal?(uri.host)
          raise InternalWebhookError, "#{url.inspect} maps to an internal address"
        end
      end

      private

      attr_reader :url

      def internal?(host)
        address = self.class.getaddress(host)

        self.class.setaddress(host, address)

        PRIVATE_ADDRESS_SUBNETS.any? do |subnet|
          subnet === IPAddr.new(address.to_s)
        end
      rescue Resolv::ResolvError
        true # localhost
      end

      def allow_internal_webhooks?
        var = ENV["CODECLIMATE_ALLOW_INTERNAL_WEBHOOKS"] || ""
        var == "1" || var == "true"
      end
    end
  end
end
