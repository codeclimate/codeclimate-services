# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
VERSION = File.read(File.expand_path("../VERSION", __FILE__))

Gem::Specification.new do |spec|
  spec.name          = "codeclimate-services"
  spec.version       = VERSION
  spec.authors       = ["Bryan Helmkamp"]
  spec.email         = ["bryan@brynary.com"]
  spec.summary       = %q{Service classes for Code Climate}
  spec.description   = %q{Service classes for Code Climate}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "0.8.8"
  spec.add_dependency "virtus", "1.0.0"
  spec.add_dependency "nokogiri", "~> 1.6.0"
  spec.add_dependency "activemodel", ">= 3.0"
  spec.add_dependency "activesupport", ">= 3.0"
  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "mocha"
end
