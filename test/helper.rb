require 'test/unit'
require 'mocha/test_unit'
require 'pp'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

cwd = File.expand_path(File.dirname(__FILE__))
require "#{cwd}/../config/load"
require "#{cwd}/fixtures"
Dir["#{cwd}/support/*.rb"].each do |helper|
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

  def service(klass, data, payload, repo_config = FalsyRepoConfig.new)
    service = klass.new(data, payload, repo_config)
    service.http :adapter => [:test, @stubs]
    service
  end

  def receive(*args)
    service(*args).receive
  end

  def service_post(*args)
    service(
      CC::Service,
      { data: "my data" },
      event(:quality, to: "D", from: "C")
    ).service_post(*args)
  end

  def stub_http(url, response = nil, &block)
    block ||= lambda{|*args| response }
    @stubs.post(url, &block)
  end

  class FalsyRepoConfig
    def method_missing(*args)
      false
    end
  end

  class TruthyRepoConfig
    def method_missing(*args)
      true
    end
  end
end
