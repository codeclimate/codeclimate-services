require "active_support/concern"
require "cc/service/response_check"

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
  end

  def service_get(url = nil, body = nil, headers = nil, &block)
    raw_get(url, body, headers, &block)
  end

  def service_post(url, body = nil, headers = nil, &block)
    block ||= lambda{|*args| Hash.new }
    response = raw_post(url, body, headers)
    {
      ok: response.success?,
      params: body.as_json,
      endpoint_url: url,
      status: response.status,
      message: "Success"
    }.merge(block.call(response))
  end

  def raw_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
    end
  end

  def raw_post(url = nil, body = nil, headers = nil)
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
        b.use(CC::Service::ResponseCheck)
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
    @ca_file ||= ENV.fetch("CODECLIMATE_CA_FILE", File.expand_path('../../../../config/cacert.pem', __FILE__))
  end

end
