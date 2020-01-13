# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

eval_gemfile 'Gemfile.devtools'

gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

gem 'rom', github: 'rom-rb/rom', branch: 'master' do
  gem 'rom-core'
end

group :test do
  gem 'rom-sql', github: 'rom-rb/rom-sql', branch: 'master'
  gem 'inflecto'
  gem 'pry-byebug', platforms: :ruby
  gem 'pry', platforms: :jruby

  gem 'pg', '~> 0.21', platforms: :ruby
  gem 'jdbc-postgres', platforms: :jruby
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
