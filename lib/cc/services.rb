require "faraday"
require "nokogiri"
require "virtus"
require "active_model"
require "active_support/core_ext"

module CC
  def self.require_all(directory)
    dir = File.expand_path("../#{directory}", __FILE__)
    Dir["#{dir}/**/*.rb"].each { |f| require f }
  end
end

require "cc/service"
CC.require_all "helpers"
CC.require_all "formatters"
CC.require_all "services"
