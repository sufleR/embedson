# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'embedson/version'

Gem::Specification.new do |spec|
  spec.name          = "embedson"
  spec.version       = Embedson::VERSION
  spec.authors       = ["sufleR"]
  spec.email         = ["szymon.fracczak@netguru.co"]
  spec.summary       = %q{Embedded model for AR with postgresql}
  spec.description   = %q{Save hash representation of class in json column as embedded model.}
  spec.homepage      = "https://github.com/sufleR/embedson"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_dependency "activerecord", ">= 4"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "pg", "~> 0.18"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "with_model", "~> 1.2"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4"

end
