# frozen_string_literal: true

if RUBY_ENGINE == 'ruby' && ENV['COVERAGE'] == 'true'
  require 'yaml'
  rubies = YAML.safe_load(File.read(File.join(__dir__, '..', '.travis.yml')))['rvm']
  latest_mri = rubies.select { |v| v =~ /\A\d+\.\d+.\d+\z/ }.max

  if RUBY_VERSION == latest_mri
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end
  end
end

SPEC_ROOT = root = Pathname(__FILE__).dirname

begin
  require 'pry-byebug'
rescue LoadError
  require 'pry'
end

require 'rom-factory'
require 'rspec'

Dir[root.join('support/*.rb').to_s].each do |f|
  require f
end

Dir[root.join('shared/*.rb').to_s].each do |f|
  require f
end

DB_URI = ENV.fetch('DATABASE_URL') do
  if defined? JRUBY_VERSION
    'jdbc:postgresql://localhost/rom_factory'
  else
    'postgres://localhost/rom_factory'
  end
end

def local_database_url?
  ['localhost', '0.0.0.0', '127.0.0.1'].any? { |host| DB_URI.include?(host) }
end

unless local_database_url?
  warn "DATABASE_URL (#{DB_URI}) is not a local database, aborting " \
       "to ensure we don't destroy production data."
  abort
end

warning_api_available = RUBY_VERSION >= '2.4.0'

module SileneceWarnings
  def warn(str)
    if str['/sequel/'] || str['/rspec-core']
      nil
    else
      super
    end
  end
end

module Helpers
  def attribute(type, name, *args)
    ROM::Factory::Attributes.const_get(type).new(name, *args)
  end

  def value(name, *args)
    attribute(:Value, name, *args)
  end

  def sequence(name, &block)
    attribute(:Sequence, name, &block)
  end

  def callable(name, *args, &block)
    attribute(:Callable, name, *args, nil, block)
  end
end

Warning.extend(SileneceWarnings) if warning_api_available

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = warning_api_available
  config.include(Helpers)
  config.before { ROM::Factory::Sequences.instance.reset }
end
