source 'https://rubygems.org'

gemspec

gem 'rake', '~> 12.0'
gem 'simplecov', require: false, platform: :mri
gem 'codeclimate-test-reporter', require: false, platform: :mri

gem 'rspec', '~> 3.0'
gem 'rom', '~> 3.0'
gem 'rom-sql', '~> 1.0'
gem 'sqlite3', '~> 1.3', platforms: [:mri, :rbx]
gem 'jdbc-sqlite3', platforms: :jruby

group :tools do
  gem 'byebug', platform: :mri
end

group :benchmarks do
  gem 'activerecord'
  gem 'benchmark-ips'
  gem 'factory_girl'
  gem 'pg'
  gem 'fabrication'
end
