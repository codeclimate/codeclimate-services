require "ipaddr"
require "resolv"

module CC
  class Service
    class SafeWebhook
      InvalidWebhookURL = Class.new(StandardError)

      # https://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces
      # https://en.wikipedia.org/wiki/Private_network#Private_IPv6_addresses
      PRIVATE_ADDRESS_SUBNETS = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16"),
        IPAddr.new("fd00::/8"),
        IPAddr.new("127.0.0.1"),
        IPAddr.new("0:0:0:0:0:0:0:1"),
      ].freeze

      def self.getaddress(host)
        @resolv ||= Resolv::DNS.new
        @resolv.getaddress(host).to_s
      end

      def initialize(url)
        @url = url
      end

      # Resolve the Host to an IP address, validate that it doesn't point to
      # anything internal, then alter the request to be for the IP directly with
      # an explicit Host header given.
      #
      # See http://blog.fanout.io/2014/01/27/how-to-safely-invoke-webhooks/#ip-address-blacklisting
      def validate!(request)
        uri = URI.parse(url)
        address = self.class.getaddress(uri.host)

        if internal?(address)
          raise_invalid("resolves to a private IP address")
        end

        alter_request(request, uri, address)
      rescue URI::InvalidURIError, Resolv::ResolvError, Resolv::ResolvTimeout => ex
        raise_invalid(ex.message)
      end

      private

      attr_reader :url

      def internal?(address)
        ip_addr = IPAddr.new(address)

        PRIVATE_ADDRESS_SUBNETS.any? do |subnet|
          subnet === ip_addr
        end
      end

      def alter_request(request, uri, address)
        address_uri = uri.dup
        address_uri.host = address
        request.url(address_uri.to_s)
        request.headers.update(Host: uri.host)
      end

      def raise_invalid(message)
        raise InvalidWebhookURL, "The Webhook URL #{url} is invalid: #{message}"
      end
    end
  end
end
