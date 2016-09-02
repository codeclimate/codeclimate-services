# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$:.unshift(lib) unless $:.include?(lib)
require "cc/services/version"

Gem::Specification.new do |spec|
  spec.name = "codeclimate-services"
  spec.version = CC::Services::VERSION
  spec.authors = ["Bryan Helmkamp"]
  spec.email = ["bryan@brynary.com"]
  spec.summary = "Service classes for Code Climate"
  spec.description = "Service classes for Code Climate"
  spec.homepage = ""
  spec.license = "MIT"

  spec.files = `git ls-files`.split($/)
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "0.8.8"
  spec.add_dependency "virtus", "~> 1.0.0"
  spec.add_dependency "nokogiri", "~> 1.6.0"
  spec.add_dependency "activemodel", ">= 3.0"
  spec.add_dependency "activesupport", ">= 3.0"
  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
