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
  spec.description   = %q{Save any class which respond to to_h in json column as embedded model.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "with_model"

end
