# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

gem 'rom', github: 'rom-rb/rom', branch: 'master' do
  gem 'rom-core'
end

group :test do
  gem 'rom-sql', github: 'rom-rb/rom-sql', branch: 'master'
  gem 'inflecto'
  gem 'pry-byebug', platforms: :mri
  gem 'pry', platforms: :jruby
  gem 'codeclimate-test-reporter'
  gem 'simplecov'

  gem 'pg', '~> 0.21', platforms: [:mri, :truffleruby]
  gem 'jdbc-postgres', platforms: :jruby
  gem 'warning'
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
