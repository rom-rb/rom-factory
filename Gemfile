# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "faker", "~> 3.0"

gem "rspec", "~> 3.0"

git "https://github.com/rom-rb/rom.git", branch: "release-5.3" do
  gem "rom"
  gem "rom-changeset"
  gem "rom-core"
  gem "rom-repository"
end

group :test do
  gem "pry"
  gem "pry-byebug", "~> 3.8", platforms: :ruby
  gem "rom-sql", github: "rom-rb/rom-sql", branch: "release-3.6"

  gem "jdbc-postgres", platforms: :jruby
  gem "pg", "~> 1.5", platforms: :ruby
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
