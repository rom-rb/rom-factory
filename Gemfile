source 'https://rubygems.org'

gemspec

gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

group :test do
  gem 'rom-sql', '~> 2.1'
  gem 'rom-core', '~> 4.2', '>= 4.2.1'
  gem 'inflecto'
  gem 'pry-byebug', platforms: :mri
  gem 'pry', platforms: :jruby
  gem 'codeclimate-test-reporter'
  gem 'simplecov'

  gem 'pg', '~> 0.21', platforms: [:mri, :truffleruby]
  gem 'mysql2', platforms: [:mri, :truffleruby]
  gem 'jdbc-postgres', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', '~> 1.3', platforms: [:mri, :truffleruby]
  gem 'jdbc-sqlite3', platforms: :jruby
end

group :tools do
  gem 'byebug', platform: :mri
  gem 'redcarpet' # for yard
end

group :benchmarks do
  gem 'activerecord'
  gem 'benchmark-ips'
  gem 'factory_bot'
  gem 'fabrication'
end
