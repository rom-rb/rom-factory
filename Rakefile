require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :spec do
  require 'rspec/core'
  DB_URIS = [
    'sqlite::memory',
    'postgres://localhost/rom_factory',
    'mysql2://root@localhost/rom_factory?sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'
  ]

  DB_URIS.each do |db_url|
    ENV['DATABASE_URL'] = db_url
    RSpec::Core::Runner.run(['spec'])
  end

end

task :default => :spec
