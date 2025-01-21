# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

gem "faker", "~> 3.0"

gem "rspec", "~> 3.0"

gem "dotenv"

git "https://github.com/rom-rb/rom.git", branch: "release-5.4" do
  gem "rom"
  gem "rom-changeset"
  gem "rom-core"
  gem "rom-repository"
end

group :test do
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
    gem 'debug'
  else
    gem "pry"
    gem "pry-byebug", "~> 3.8", platforms: :ruby
  end
  gem "rom-sql", github: "rom-rb/rom-sql", branch: "release-3.7"

  gem "jdbc-postgres", platforms: :jruby
  gem "pg", "~> 1.5", platforms: :ruby
end

group :tools do
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
    gem "byebug", platform: :mri
  else
    gem "pry-byebug", "~> 3.8", platforms: :ruby
  end
  gem "redcarpet" # for yard
end

group :benchmarks do
  gem "activerecord"
  gem "benchmark-ips"
  gem "fabrication"
  gem "factory_bot"
end
