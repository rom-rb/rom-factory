[gem]: https://rubygems.org/gems/rom-factory
[actions]: https://github.com/rom-rb/rom-factory/actions
[codeclimate]: https://codeclimate.com/github/rom-rb/rom-factory
[inchpages]: http://inch-ci.org/github/rom-rb/rom-factory

# rom-factory

[![Gem Version](https://badge.fury.io/rb/rom-factory.svg)][gem]
[![CI Status](https://github.com/rom-rb/rom-factor/workflows/ci/badge.svg)][actions]
[![Code Climate](https://codeclimate.com/github/rom-rb/rom-factory/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/rom-rb/rom-factory/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-factory.svg?branch=master)][inchpages]

Data generator with support for persistence backends, built on top of [rom-rb](http://rom-rb.org) and [dry-rb](http://dry-rb.org).

More information:

- [API docs](http://rubydoc.info/gems/rom-factory)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom-factory'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom-factory

### Performance

Seems like this thing is a bit faster than other popular factory gems:

```
Warming up --------------------------------------
         rom-factory     1.000  i/100ms
        factory_girl     1.000  i/100ms
         fabrication     1.000  i/100ms
Calculating -------------------------------------
         rom-factory      1.550  (± 0.0%) i/s -      8.000  in   5.166227s
        factory_girl      0.982  (± 0.0%) i/s -      5.000  in   5.098193s
         fabrication      1.011  (± 0.0%) i/s -      6.000  in   5.942209s

Comparison:
         rom-factory:        1.5 i/s
         fabrication:        1.0 i/s - 1.53x  slower
        factory_girl:        1.0 i/s - 1.58x  slower
```

> See [benchmarks/basic.rb](https://github.com/rom-rb/rom-factory/blob/master/benchmarks/basic.rb)

## Credits

This project was originally created by [Jānis Miezītis](https://github.com/janjiss) and eventually moved to `rom-rb` organization.

## License

See `LICENSE.txt` file.
