# RomFactory

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rom_factory`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom_factory'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom_factory

## Usage

```ruby
container = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :last_name, String, null: false
    column :first_name, String, null: false
    column :email, String, null: false
    column :created_at, Time, null: false
    column :updated_at, Time, null: false
  end
  conf.relation(:users) do
    schema(:users, infer: true) do

    end
  end
end

class MappedUser
  def self.call(attrs)
    OpenStruct.new(attrs)
  end
end

RepoClass = Class.new(ROM::Repository[:users]) do
  commands :create
end

RomFactory::Builder.define(container) do
  factory(repo: RepoClass, name: :user, as: MappedUser) do
    first_name "Janis"
    last_name "Miezitis"
    email "janjiss@gmail.com"
    created_at Time.now
    updated_at Time.now
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
