require 'rom-factory'
require 'rom'
require 'active_record'
require 'factory_girl'
require 'fabrication'
require 'benchmark/ips'

DATABASE_URL = 'postgres://localhost/rom_factory'.freeze

rom = ROM.container(:sql, DATABASE_URL) do |conf|
  conf.default.connection.create_table?(:users) do
    primary_key :id
    column :last_name, String, null: false
    column :first_name, String, null: false
    column :admin, TrueClass
  end
end

factory = ROM::Factory.configure { |c| c.rom = rom }

factory.define(:user) do |f|
  f.first_name "John"
  f.last_name "Doe"
  f.admin false
end

class User < ActiveRecord::Base
end

ActiveRecord::Base.establish_connection(DATABASE_URL)

FactoryGirl.define do
  factory(:user) do
    first_name "John"
    last_name  "Doe"
    admin false
  end
end

Fabricator(:user) do
  first_name "John"
  last_name  "Doe"
  admin false
end

Benchmark.ips do |x|
  x.report('rom-factory persisted struct') do
    1000.times do
      factory[:user]
    end
  end

  x.report('factory_girl') do
    1000.times do
      FactoryGirl.create(:user)
    end
  end

  x.report('fabrication') do
    1000.times do
      Fabricate(:user)
    end
  end

  x.compare!
end
