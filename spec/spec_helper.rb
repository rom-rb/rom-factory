require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'sqlite3'
require 'pry'

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
