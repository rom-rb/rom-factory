# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

gem 'dry-logic', '~> 1.0', github: 'dry-rb/dry-logic', branch: 'master'
gem 'dry-types', '~> 1.0', github: 'dry-rb/dry-types', branch: 'master'
gem 'dry-struct', '~> 1.0', github: 'dry-rb/dry-struct', branch: 'master'

group :test do
  gem 'rom-sql', '~> 3.0', github: 'rom-rb/rom-sql', branch: 'master'
  gem 'rom', github: 'rom-rb/rom', branch: 'master' do
    gem 'rom-core'
  end

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
