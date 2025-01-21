# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rom/factory/version"

Gem::Specification.new do |spec|
  spec.name          = "rom-factory"
  spec.version       = ROM::Factory::VERSION
  spec.authors       = ["Janis Miezitis", "Piotr Solnica"]
  spec.email         = ["janjiss@gmail.com", "piotr.solnica@gmail.com"]

  spec.summary       = "ROM based builder library to make your specs awesome. DSL partially inspired by FactoryBot."
  spec.description   = ""
  spec.homepage      = "https://github.com/rom-rb/rom-factory"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "dry-configurable", "~> 1.3"
  spec.add_dependency "dry-core", "~> 1.1"
  spec.add_dependency "dry-struct", "~> 1.7"
  spec.add_dependency "faker", ">= 2.0", "< 4"
  spec.add_dependency "rom-core", "~> 5.4"
end
