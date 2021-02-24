---
position: 7
chapter: Factory
---

# rom-factory

`rom-factory` provides a simple API for creating and persisting `ROM::Struct`'s. If you already know FactoryBot you'll definitely understand the concept.

## Installation

First of all you need to define a ROM Container for Factory. For example if you are using `rspec`, you can add these lines to `spec_helper.rb`. Also you need to require here all files with Factories.

```ruby
Factory = ROM::Factory.configure do |config|
  config.rom = my_rom_container
end

Dir[File.dirname(__FILE__) + '/support/factories/*.rb'].each { |file| require file }
```

## Usage

### Define factory

```ruby
# 'spec/support/factories/users.rb'

Factory.define(:user) do |f|
  f.name 'John'
  f.age 42
end
```
#### Specify relations

You can specify ROM relation if you want. It'll be pluralized factory name by default.

```ruby
Factory.define(:user, relation: :people) do |f|
  f.name 'John'
  f.age 42
end
```

#### Specify namespace for your structs

Struct `User` will be find in MyApp::Entities namespace

```ruby
Factory.define(:user, struct_namespace: MyApp::Entities) do |f|
  # ...
end
```

#### Sequences

You can use sequences for uniq fields

```ruby
Factory.define(:user) do |f|
  f.name 'John'
  f.sequence(:email) { |n| "john#{n}@example.com" }
end
```

#### Timestamps

```ruby
Factory.define(:user) do |f|
  f.name 'John'
  f.timestamps
  # same as
  # f.created_at { Time.now }
  # f.updated_at { Time.now }
end
```

#### Associations

* belongs_to

```ruby
Factory.define(:group) do |f|
  f.name 'Admins'
end

Factory.define(:user) do |f|
  f.name 'John'
  f.association(:user)
end
```

* has_many

```ruby
Factory.define(:group) do |f|
  f.name 'Admins'
  f.association(:user, count: 2)
end

Factory.define(:user) do |f|
  f.name 'John'
end
```

#### Extend already existing factory

```ruby
Factory.define(:user) do |f|
  f.name 'John'
  f.admin false
end

Factory.define(admin: :user) do |f|
  f.admin true
end

# Factory.structs(:admin)
```

#### Traits

```ruby
Factory.define(:user) do |f|
  f.name 'John'
  f.admin false

  f.trait :with_age do |t|
    t.age 42
  end
end

# Factory.structs(:user, :with_age)
```

#### Build-in [Faker](https://github.com/faker-ruby/faker) objects

```ruby
Factory.define(:user) do |f|
  f.email { fake(:internet, :email) }
end
```

#### Dependent attributes

Attributes can be based on the values of other attributes:

```ruby
Factory.define(:user) do |f|
  f.full_name { fake(:name) }
  # Dependent attributes are inferred from the block parameter names:
  f.login { |full_name| full_name.downcase.gsub(/\s+/, '_') }
  # Works with sequences too:
  f.sequence(:email) { |n, login| "#{login}-#{n}@example.com" }
end
```

### Build and persist objects

```ruby
# Create in-memory object
Factory.structs[:user]

# Persist struct in database
Factory[:user]

# Override attributes
Factory[:user, age: 24]
```
