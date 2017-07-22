require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :spec do
  require 'rspec/core'

  DB_URIS = if defined? JRUBY_VERSION
    {
     sqlite: 'jdbc:sqlite:::memory',
     postgres: 'jdbc:postgresql://localhost/rom_factory',
     mysql: 'jdbc:mysql://localhost/rom_factory?user=root&sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'
    }
  else
    {
      sqlite: 'sqlite::memory',
      postgres: 'postgres://localhost/rom_factory',
      mysql: 'mysql2://root@localhost/rom_factory?sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'
    }
  end

  DB_URIS.each do |adapter, db_url|
    ENV['ADAPTER'] = adapter.to_s
    ENV['DATABASE_URL'] = db_url
    RSpec::Core::Runner.run(['spec'])
    RSpec.clear_examples
  end
end

task :default => :spec
