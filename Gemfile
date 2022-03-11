# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

eval_gemfile 'Gemfile.devtools'

gem 'faker', "~> #{ENV['FAKER'].eql?('faker-1') ? '1.7' : '2.8'}"

gem 'rspec', '~> 3.0'

group :test do
  gem 'rom-sql'
  gem 'pry-byebug', '~> 3.8', platforms: :ruby
  gem 'pry', '~> 0.12.0', '<= 0.13'

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
