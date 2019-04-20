# frozen_string_literal: true

require 'rom-factory'
require 'rom-core'
require 'active_record'
require 'factory_bot'
require 'fabrication'
require 'benchmark/ips'

DATABASE_URL = 'postgres://localhost/rom_factory_bench'.freeze

rom = ROM.container(:sql, DATABASE_URL) do |conf|
  conf.default.connection.create_table?(:users) do
    primary_key :id
    column :last_name, String, null: false
    column :first_name, String, null: false
    column :admin, TrueClass
  end

  conf.relation(:users) do
    schema(infer: true)
  end
end

factory = ROM::Factory.configure { |c| c.rom = rom }

factory.define(:user) do |f|
  f.first_name { "John" }
  f.last_name { "Doe" }
  f.admin { false }
end

class User < ActiveRecord::Base
end

ActiveRecord::Base.establish_connection(DATABASE_URL)

FactoryBot.define do
  factory(:user) do
    first_name { "John" }
    last_name  { "Doe" }
    admin { false }
  end
end

Fabricator(:user) do
  first_name { "John" }
  last_name  { "Doe" }
  admin { false }
end

Benchmark.ips do |x|
  x.report('rom-factory persisted struct') do
    factory[:user]
  end

  x.report('factory_bot') do
    FactoryBot.create(:user)
  end

  x.report('fabrication') do
    Fabricate(:user)
  end

  x.compare!
end
