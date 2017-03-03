if ENV['COVERAGE'] == 'true' && RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.4.0' && ENV['CI'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'rom'
require 'rom/factory'
require 'rspec'

begin
  require 'byebug'
rescue LoadError
  # not mri
end

RSpec.configure do |config|
  config.disable_monkey_patching!
end
