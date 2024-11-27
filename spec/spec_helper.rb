# frozen_string_literal: true

require_relative "support/coverage"
require "dotenv"
Dotenv.load(".postgres.env", ".env")

require "pathname"
SPEC_ROOT = root = Pathname(__FILE__).dirname

require "rom-factory"
require "byebug"
require "rspec"

Dir[root.join("support/*.rb").to_s].sort.each do |f|
  require f
end

Dir[root.join("shared/*.rb").to_s].sort.each do |f|
  require f
end

DB_URI = ENV.fetch("DATABASE_URL") do
  auth = ENV.values_at("POSTGRES_USER", "POSTGRES_PASSWORD").join(":")
  address = `docker compose port db 5432 2> /dev/null`.strip
  address = [auth, address].join("@") if address

  address ||= "localhost"

  if defined? JRUBY_VERSION
    "jdbc:postgresql://#{address}"
  else
    "postgres://#{address}"
  end
end

warning_api_available = RUBY_VERSION >= "2.4.0"

module SileneceWarnings
  def warn(str)
    if str["/sequel/"] || str["/rspec-core"]
      nil
    else
      super
    end
  end
end

module Helpers
  def attribute(type, *args, **kwargs)
    ROM::Factory::Attributes.const_get(type).new(*args, **kwargs)
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
  config.filter_run_when_matching :focus
end
