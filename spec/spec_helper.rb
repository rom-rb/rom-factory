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

SPEC_ROOT = root = Pathname(__FILE__).dirname

begin
  require 'pry-byebug'
rescue LoadError
  require 'pry'
end

require 'rom-factory'
require 'rom-sql'
require 'rom'
require 'rspec'

Dir[root.join('support/*.rb').to_s].each do |f|
  require f
end

Dir[root.join('shared/*.rb').to_s].each do |f|
  require f
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

def adapter
  ENV['ADAPTER'] || 'sqlite'
end

def database_url
  ENV['DATABASE_URL'] || 'sqlite::memory'
end

def with_adapters(*args, &block)
  context("with #{adapter}", &block)
end

Test.setup(database_url)

Warning.extend(SileneceWarnings) if warning_api_available

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = warning_api_available

  config.around(:each) do |example|
    Test::CONN.transaction do
      example.run
    end
  end

  config.after(:suite) do
    ENV.delete('DATABASE_URL')
    ENV.delete('ADAPTER')
  end
end
