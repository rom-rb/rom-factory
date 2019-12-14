# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rom/factory/version'

Gem::Specification.new do |spec|
  spec.name          = "rom-factory"
  spec.version       = ROM::Factory::VERSION
  spec.authors       = ["Janis Miezitis", "Piotr Solnica"]
  spec.email         = ["janjiss@gmail.com", "piotr.solnica@gmail.com"]

  spec.summary       = %q{ROM based builder library to make your specs awesome. DSL partially inspired by FactoryGirl.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/rom-rb/rom-factory"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable", "~> 0.7"
  spec.add_dependency "dry-core", "~> 0.4"
  spec.add_dependency 'faker', '>= 1.7', '< 3.0'
  spec.add_dependency 'rom-core', '~> 5.0'

  spec.add_development_dependency 'appraisal'
end
