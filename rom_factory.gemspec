# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rom_factory/version'

Gem::Specification.new do |spec|
  spec.name          = "rom_factory"
  spec.version       = RomFactory::VERSION
  spec.authors       = ["Janis Miezitis"]
  spec.email         = ["janjiss@gmail.com"]

  spec.summary       = %q{Factory builder for rom rb}
  spec.description   = %q{Inspired by FactoryGril, factory builder for ROM }
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rom", "~> 2.0"
  spec.add_development_dependency "rom-repository", "~> 0.3.1"
  spec.add_development_dependency "pry"
end
