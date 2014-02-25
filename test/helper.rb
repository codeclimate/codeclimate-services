require 'test/unit'
require 'pp'
require File.expand_path('../../config/load', __FILE__)
require File.expand_path('../fixtures', __FILE__)

class CC::Service::TestCase < Test::Unit::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    I18n.enforce_available_locales = true
  end

  def teardown
    @stubs.verify_stubbed_calls
  end

  def service(klass, event, data, payload)
    service = klass.new(event, data, payload)
    service.http :adapter => [:test, @stubs]
    service
  end

  def receive(*args)
    service(*args).receive
  end
end
