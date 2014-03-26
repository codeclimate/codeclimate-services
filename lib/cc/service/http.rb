require 'active_support/concern'

module CC::Service::HTTP
  extend ActiveSupport::Concern

  module ClassMethods
    def default_http_options
      @@default_http_options ||= {
        adapter: :net_http,
        request: { timeout: 10, open_timeout: 5 },
        ssl:     { verify_depth: 5 },
        headers: {}
      }
    end

    attr_accessor :custom_middleware
  end

  def http_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
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
        # Any custom middleware must be specified first (outermost)
        if middelware = self.class.custom_middleware
          b.use middelware
        end

        b.request(:url_encoded)
        b.response(:raise_error)
        b.adapter(*Array(options[:adapter] || config[:adapter]))
      end
    end
  end

  # Gets the path to the SSL Certificate Authority certs.  These were taken
  # from: http://curl.haxx.se/ca/cacert.pem
  #
  # Returns a String path.
  def ca_file
    @ca_file ||= File.expand_path('../../../config/cacert.pem', __FILE__)
  end

end
