require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'sqlite3'
require 'pry'

require 'rom/factory'
require 'rspec'

RSpec.configure do |config|
  config.disable_monkey_patching!
end
