# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workable/version'

Gem::Specification.new do |spec|
  spec.name          = "workable"
  spec.version       = Workable::VERSION
  spec.authors       = ["Rafał Wojsznis"]
  spec.email         = ["rafal.wojsznis@gmail.com"]
  spec.homepage      = "https://github.com/emq/workable"
  spec.license       = "MIT"
  spec.summary = spec.description = "Dead-simple Ruby API client for workable.com"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'webmock', '~> 1.20.4'
  spec.add_development_dependency 'coveralls', '~> 0.7.2'
  spec.add_development_dependency 'guard', '~> 2.12'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
end
