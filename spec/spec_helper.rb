# frozen_string_literal: true

require_relative "support/coverage"
require "dotenv"
Dotenv.load(".postgres.env", ".env")

require "pathname"
require "uri"
SPEC_ROOT = root = Pathname(__FILE__).dirname

require "rom-factory"

%w[debug byebug pry].each do |debugger|
  require debugger
rescue LoadError
  # ignore
else
  break
end

require "rspec"

Dir[root.join("support/*.rb").to_s].each do |f|
  require f
end

Dir[root.join("shared/*.rb").to_s].each do |f|
  require f
end

DB_URI = ENV.fetch("DATABASE_URL") do
  user, password = ENV.values_at("POSTGRES_USER", "POSTGRES_PASSWORD")
  database = ENV.fetch("POSTGRES_DATABASE", "rom_factory")
  address = `docker compose port db 5432 2> /dev/null`.lines.first.to_s.strip
  address = "localhost" if address.empty?

  if defined? JRUBY_VERSION
    "jdbc:postgresql://#{address}/#{database}?user=#{user}&password=#{password}"
  else
    "postgres://#{user}:#{password}@#{address}/#{database}"
  end
end

if defined?(JRUBY_VERSION) && DB_URI.start_with?("postgres://", "postgresql://")
  uri = URI.parse(DB_URI)
  params = URI.decode_www_form(uri.query.to_s).to_h
  params["user"] ||= uri.user if uri.user
  params["password"] ||= uri.password if uri.password

  DB_URI = "jdbc:postgresql://#{uri.host}:#{uri.port}#{uri.path}?#{URI.encode_www_form(params)}".freeze
end

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

  def sequence(name, &)
    attribute(:Sequence, name, &)
  end

  def callable(name, *args, &block)
    attribute(:Callable, name, *args, nil, block)
  end
end

Warning.extend(SileneceWarnings)

RSpec.configure do |config|
  config.include(Helpers)
  config.before { ROM::Factory::Sequences.instance.reset }
end
