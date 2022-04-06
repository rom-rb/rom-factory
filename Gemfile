# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "faker", "~> 2.8"

gem "rspec", "~> 3.0"

group :test do
  gem "rom", github: 'rom-rb/rom', branch: "main"
  gem "rom-sql", github: "rom-rb/rom-sql", branch: "main"
  gem "pry", "~> 0.12.0", "<= 0.13"
  gem "pry-byebug", "~> 3.8", platforms: :ruby

  gem "jdbc-postgres", platforms: :jruby
  gem "pg", "~> 0.21", platforms: :ruby
end

group :tools do
  gem "byebug", platform: :mri
  gem "redcarpet" # for yard
end

group :benchmarks do
  gem "activerecord"
  gem "benchmark-ips"
  gem "fabrication"
  gem "factory_bot"
end
