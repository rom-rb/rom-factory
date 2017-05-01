if RUBY_ENGINE == 'ruby' && ENV['COVERAGE'] == 'true'
  require 'yaml'
  rubies = YAML.load(File.read(File.join(__dir__, '..', '.travis.yml')))['rvm']
  latest_mri = rubies.select { |v| v =~ /\A\d+\.\d+.\d+\z/ }.max

  if RUBY_VERSION == latest_mri
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end
  end
end

require 'rom'
require 'rom-factory'
require 'rom-sql'
require 'rspec'

begin
  require 'pry-byebug'
rescue LoadError
  require 'pry'
end

if defined? JRUBY_VERSION
  DB_URIS = {
    sqlite: 'jdbc:sqlite:::memory',
    postgres: 'jdbc:postgresql://localhost/rom_factory',
    mysql: 'jdbc:mysql://localhost/rom_factory?user=root&sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'
  }
else
  DB_URIS = {
    sqlite: 'sqlite::memory',
    postgres: 'postgres://localhost/rom_factory',
    mysql: 'mysql2://root@localhost/rom_factory?sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'
  }
end

ADAPTERS = DB_URIS.keys

def with_adapters(*args, &block)
  reset_adapter = Hash[*ADAPTERS.flat_map { |a| [a, false] }]
  adapters = args.empty? || args[0] == :all ? ADAPTERS : args

  adapters.each do |adapter|
    context("with #{adapter}", **reset_adapter, adapter => true, &block)
  end
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

Warning.extend(SileneceWarnings) if warning_api_available

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = warning_api_available
end
