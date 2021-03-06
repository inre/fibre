# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fibre/version'

Gem::Specification.new do |spec|
  spec.name          = 'fibre'
  spec.version       = Fibre::VERSION
  spec.authors       = ['inre']
  spec.email         = ['inre.storm@gmail.com']
  spec.summary       = 'Fiber pool for Ruby'
  spec.description   = spec.summary
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version     = '>= 2.1.0'
  spec.required_rubygems_version = '>= 2.3.0'

  spec.add_dependency 'event_object', '~> 1'

  spec.add_development_dependency 'eventmachine', '~> 1.2'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
end
