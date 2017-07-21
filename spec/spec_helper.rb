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

module Test
  class UserRelation < ROM::Relation[:sql]
    schema(:users) do
      attribute :id, Types::Int
      attribute :last_name, Types::String
      attribute :first_name, Types::String
      attribute :email, Types::String
      attribute :age, Types::Int
      attribute :created_at, Types::Time
      attribute :updated_at, Types::Time

      primary_key :id

      associations do
        has_many :tasks
      end
    end
  end

  class TaskRelation < ROM::Relation[:sql]
    schema(:tasks) do
      attribute :id, Types::Int
      attribute :user_id, Types::Int
      attribute :title, Types::String

      primary_key :id

      associations do
        belongs_to :user
      end
    end
  end
end

Test::CONF = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])

Test::CONF.register_relation(Test::UserRelation)
Test::CONF.register_relation(Test::TaskRelation)

Test::ROM = ROM.container(Test::CONF)

Test::CONN = Test::CONF.gateways[:default].connection

Warning.extend(SileneceWarnings) if warning_api_available

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = warning_api_available

  config.around(:each) do |example|
    Test::CONN.transaction do
      example.run
    end
  end
end
