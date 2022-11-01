# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "faker", "~> 2.8"

gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-configurable", github: "dry-rb/dry-configurable", branch: "main"

gem "rspec", "~> 3.0"

group :test do
  gem "pry", "~> 0.12.0", "<= 0.13"
  gem "pry-byebug", "~> 3.8", platforms: :ruby
  gem "rom-sql"

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
