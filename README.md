[gem]: https://rubygems.org/gems/rom-factory
[travis]: https://travis-ci.org/rom-rb/rom-factory
[gemnasium]: https://gemnasium.com/rom-rb/rom-factory
[codeclimate]: https://codeclimate.com/github/rom-rb/rom-factory
[inchpages]: http://inch-ci.org/github/rom-rb/rom-factory

# rom-factory

[![Gem Version](https://badge.fury.io/rb/rom-factory.svg)][gem]
[![Build Status](https://travis-ci.org/rom-rb/rom-factory.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/rom-rb/rom-factory.svg)][gemnasium]
[![Code Climate](https://codeclimate.com/github/rom-rb/rom-factory/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/rom-rb/rom-factory/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-factory.svg?branch=master)][inchpages]

Data generator with support for persistence backends, built on top of [rom-rb](http://rom-rb.org) and [dry-rb](http://dry-rb.org).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom-factory'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom-factory

## Configuration

First, you have to define ROM container:

```ruby
rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :last_name, String, null: false
    column :first_name, String, null: false
    column :email, String, null: false
    column :admin, TrueClass, null: false, default: false
    column :created_at, Time, null: false
    column :updated_at, Time, null: false
  end
end
```

> Notice that if you're using ROM in your application, then simply set up factory using your existing ROM container

Once that is done, you will have to specify which container ROM::Factory will use:

```ruby
Factory = ROM::Factory.configure do |config|
  config.rom = rom
end
```

This returns a new factory ready to be used.

## Simple use case

After configuration is done, you can define builders using your `Factory`:

```ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
end
```

Then you can use it to generate data:

```ruby
user = Factory[:user]
user.email #=> "janjiss@gmail.com"
```

### Callable properties

You can easily define dynamic (callbale) properties if value needs to change every time it needs to be called.
Anything that responds to `.call` can be a dynamic property.

```ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
  f.created_at {Time.now}
end

user = Factory[:user]
user.created_at #=> 2016-08-27 18:17:08 -0500
```

### Sequencing

If you want attributes to be unique each time you generate data, you can use sequence to achieve that:

```ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.sequence :email do |n|
    "janjiss#{n}@gmail.com"
  end
end

user1 = Factory[:user]
user2 = Factory[:user]

user1.email #=> janjiss1@gmail.com
user2.email #=> janjiss2@gmail.com
```

### Timestamps

There is a support for timestamps for `created_at` and `updated_at` attributes:

```ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
  f.timestamps
end

user = Factory[:user]
user.created_at #=> 2016-08-27 18:17:08 -0500
user.updated_at #=> 2016-08-27 18:17:10 -0500
```

### Associations

If you defined associations in your relations, you can use `association` builder:

``` ruby
factories.define(:user) do |f|
  f.first_name 'Jane'
  f.last_name 'Doe'
  f.email 'jane@doe.org'
  f.timestamps
end

factories.define(:task) do |f|
  f.title 'A task'
  f.association(:user)
end

task = factories[:task]
```

> Currently only `belongs_to` is supported

### Fake data generator

There's a builtin support for [Faker](https://github.com/stympy/faker) gem with a `fake` shortcut in the DSL:


``` ruby
factories.define(:user) do |f|
  f.first_name { fake(:name, :first_name) }
  f.last_name { fake(:name, :last_name) }
  f.email { fake(:internet, :email) }
  f.timestamps
end
```

### Extending existing builders

You can create a hierarchy of builders easily, which is useful if you want to share data generation logic across
multiple definitions:

``` ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
  f.admin false
  f.timestamps
end

Factory.define(admin: :user) do |f|
  f.admin true
end

user = Factory[:admin]

user.admin # true
```

### Setting up relation backend explicitly

By default, relation is configured automatically based on the builder name. For example if your builder is called `:user`, then `:users`
relation name will be inferred. If you want to set up a relation explicitly, use `:relation` option:

``` ruby
Factory.define(:user, relation: :people) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
  f.admin false
  f.timestamps
end
```

### Generating structs without persistence

You can generate struct objects without persisting them using `#structs` generator:

``` ruby
Factory.define(:user) do |f|
  f.first_name "Janis"
  f.last_name "Miezitis"
  f.email "janjiss@gmail.com"
  f.admin false
  f.timestamps
end

user = Factory.structs[:user]

user.id # auto-generated fake PK
user.first_name # "Janis"
```

## Credits

This project was originally created by [Jānis Miezītis](https://github.com/janjiss) and eventually moved to `rom-rb` organization.

## License

See `LICENSE.txt` file.
