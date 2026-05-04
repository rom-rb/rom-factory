# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync. To update it, edit repo-sync.yml.

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rom/factory/version"

Gem::Specification.new do |spec|
  spec.name          = "rom-factory"
  spec.authors       = ["Hanakai team"]
  spec.email         = ["info@hanakai.org"]
  spec.license       = "MIT"
  spec.version       = ROM::Factory::VERSION.dup

  spec.summary       = "ROM based builder library to make your specs awesome. DSL partially inspired by FactoryBot."
  spec.description   = spec.summary
  spec.homepage      = "https://hanakai.org/learn/rom/factories"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "rom-factory.gemspec", "lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = Dir["exe/*"].map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE"]

  spec.metadata["changelog_uri"]     = "https://github.com/rom-rb/rom-factory/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/rom-rb/rom-factory"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/rom-rb/rom-factory/issues"
  spec.metadata["funding_uri"]       = "https://github.com/sponsors/hanami"

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_runtime_dependency "dry-configurable", "~> 1.3"
  spec.add_runtime_dependency "dry-core", "~> 1.1"
  spec.add_runtime_dependency "dry-struct", "~> 1.7"
  spec.add_runtime_dependency "faker", ">= 2.0", "< 4"
  spec.add_runtime_dependency "rom-core", "~> 5.4"
  spec.add_runtime_dependency "tsort", "~> 0.2"
end

