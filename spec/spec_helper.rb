require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

cwd = File.expand_path(File.dirname(__FILE__))
require "#{cwd}/../config/load"
require "#{cwd}/fixtures"
Dir["#{cwd}/support/*.rb"].sort.each do |helper|
  require helper
end
CC::Service.load_services

require "#{cwd}/support/service_context"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true
end
