module RSpec::ServiceContext
  before do
    @stubs = Faraday::Adapter::Test::Stubs.new

    I18n.enforce_available_locales = true
  end

  after do
    @stubs.verify_stubbed_calls
  end

  def service(klass, data, payload)
    service = klass.new(data, payload)
    service.http adapter: [:test, @stubs]
    service
  end

  def receive(*args)
    service(*args).receive
  end

  def service_post(*args)
    service(
      CC::Service,
      { data: "my data" },
      event(:quality, to: "D", from: "C"),
    ).service_post(*args)
  end

  def service_post_with_redirects(*args)
    service(
      CC::Service,
      { data: "my data" },
      event(:quality, to: "D", from: "C"),
    ).service_post_with_redirects(*args)
  end

  def stub_http(url, response = nil, &block)
    block ||= ->(*_args) { response }
    @stubs.post(url, &block)
  end
end
