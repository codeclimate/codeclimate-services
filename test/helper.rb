require "test/unit"
require "mocha/test_unit"
require "pp"

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

cwd = File.expand_path(File.dirname(__FILE__))
require "#{cwd}/../config/load"
require "#{cwd}/fixtures"
Dir["#{cwd}/support/*.rb"].sort.each do |helper|
  require helper
end
CC::Service.load_services

class CC::Service::TestCase < Test::Unit::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    I18n.enforce_available_locales = true
  end

  def teardown
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
