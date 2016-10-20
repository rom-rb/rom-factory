[![Build Status](https://travis-ci.org/janjiss/rom_factory.svg?branch=master)](https://travis-ci.org/janjiss/rom_factory)
[![Gem Version](https://badge.fury.io/rb/rom_factory.svg)](https://badge.fury.io/rb/rom_factory)
[![Dependency Status](https://gemnasium.com/badges/github.com/janjiss/rom_factory.svg)](https://gemnasium.com/github.com/janjiss/rom_factory)
[![Code Climate](https://codeclimate.com/github/janjiss/rom_factory/badges/gpa.svg)](https://codeclimate.com/github/janjiss/rom_factory)
# RomFactory

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom_factory'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom_factory

## Configuration
First, you have to define ROM container:
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
end
```
Once that is done, you will have to specify which container RomFactory will use:
```ruby
RomFactory::Config.configure do |config|
  config.container = container
end
```

## Simple use case

After configuration is done, you can define the factory as follows:
```ruby
RomFactory::Builder.define do |b|
  b.factory(relation: :users, name: :user) do |f|
    f.first_name "Janis"
    f.last_name "Miezitis"
    f.email "janjiss@gmail.com"
  end
end
```
When everything is configured, you can use it in your tests as follows:
```ruby
user = RomFactory::Builder.create(:user)
user.email #=> "janjiss@gmail.com"
```

### Callable properties
You can easily define dynamic (callbale) properties if value needs to change every time it needs to be called. Anything that responds to `.call` can be dynamic property.
```ruby
RomFactory::Builder.define do |b|
  b.factory(relation: :users, name: :user) do |f|
    f.first_name "Janis"
    f.last_name "Miezitis"
    f.email "janjiss@gmail.com"
    f.created_at {Time.now}
  end
end
user = RomFactory::Builder.create(:user)
user.created_at #=> 2016-08-27 18:17:08 -0500
```

### Sequencing

If you want attributes to be unique each time you build a factory, you can use sequence to achieve that:
```ruby
RomFactory::Builder.define do |b|
  b.factory(relation: :users, name: :user) do |f|
    f.first_name "Janis"
    f.last_name "Miezitis"
    f.sequence :email do |n|
      "janjiss#{n}@gmail.com"
    end
  end
end
user = RomFactory::Builder.create(:user)
user.email #=> janjiss1@gmail.com
user2 = RomFactory::Builder.create(:user)
user2.email #=> janjiss2@gmail.com
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
