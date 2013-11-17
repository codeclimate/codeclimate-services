# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cc/services/version'

Gem::Specification.new do |spec|
  spec.name          = "codeclimate-services"
  spec.version       = CC::Services::VERSION
  spec.authors       = ["Bryan Helmkamp"]
  spec.email         = ["bryan@brynary.com"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "0.8.8"
  spec.add_dependency "liquid", "2.5.4"
  spec.add_dependency "activesupport", "> 3.0"
  spec.add_development_dependency "bundler", "1.5.0.rc.1"
  spec.add_development_dependency "rake"
end
