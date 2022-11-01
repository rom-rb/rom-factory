# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "faker", "~> 2.8"

gem "dry-configurable", github: "dry-rb/dry-configurable", branch: "main"
gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-logic", github: "dry-rb/dry-logic", branch: "main"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"
gem "dry-struct", github: "dry-rb/dry-struct", branch: "main"

gem "rspec", "~> 3.0"

git "https://github.com/rom-rb/rom.git", branch: "release-5.3" do
  gem "rom-core"
  gem "rom-changeset"
  gem "rom-repository"
  gem "rom"
end

group :test do
  gem "pry", "~> 0.12.0", "<= 0.13"
  gem "pry-byebug", "~> 3.8", platforms: :ruby
  gem "rom-sql", github: "rom-rb/rom-sql", branch: "release-3.6"

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
