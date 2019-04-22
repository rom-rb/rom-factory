## 0.8.0 to-be-released

### Fixed

* Loaded association structs are no longer rejected by output schemas (issue #34) (flash-gordon + solnic)

[Compare v0.7.0...v0.8.0](https://github.com/rom-rb/rom-factory/compare/v0.7.0...v0.8.0)

## 0.7.0 2018-11-17

### Added

* Support for traits (v-kolesnikov)
* Support building structs with associations (@ianks)

### Fixed

* Overwritten attributes with dependencies (JanaVPetrova)

[Compare v0.6.0...v0.7.0](https://github.com/rom-rb/rom-factory/compare/v0.6.0...v0.7.0)

## 0.6.0 2018-01-31

### Added

* Support for factories with custom struct namespaces (solnic)

### Changed

* Accessing a factory which is not defined will result in `FactoryNotDefinedError` exception (GustavoCaso + solnic)

### Fixed

* Using dependent attributes with sequences works correctly, ie `f.sequence(:login) { |i, name| "name-#{i}"}` (solnic)

[Compare v0.5.0...v0.6.0](https://github.com/rom-rb/rom-factory/compare/v0.5.0...v0.6.0)

## 0.5.0 2017-10-24

### Added

* Updated to rom 4.0 (solnic)
* Support for `has_many` and `has_one` associations (solnic)
* Support for attributes depending on values from other attributes (solnic)
* Support for `rand` inside the generator block (flash-gordon)

### Changed

* Depends on `rom-core` now (solnic)

[Compare v0.4.0...v0.5.0](https://github.com/rom-rb/rom-factory/compare/v0.4.0...v0.5.0)

## v0.4.0 2017-03-03

This is a revamp of the original `rom_factory` gem which adds new features and
improves internals.

### Added

* Support for defining multiple factories via `MyFactory = ROM::Factory.configure { |c| ... }` (solnic)
* Support for builder inheritence via `define(admin: :user) { |f| ... }` (solnic)
* Support for generating in-memory structs via `MyFactory.structs[:user]` that are not persisted (solnic)
* Support for `belongs_to` associations via `f.association(:user)` (solnic)
* New DSL for defining builders `MyFactory.define(:user) { |f| ... }` which infers default relation name (solnic)
* New factory method `MyFactory#[]` ie `MyFactory[:user, name: "Jane"]` (solnic)
* New `fake` helper which uses faker gem under the hood ie `f.email { fake(:internet, :email) }` (solnic)

### Changed

* `Rom::Factory::Config.configure` was replaced with `ROM::Factory.configure` (solnic)
* Global factory config and builders are gone (solnic)
* Structs are now based on dry-struct (solnic)

[Compare v0.3.1...v0.4.0](https://github.com/rom-rb/rom-factory/compare/v0.3.1...v0.4.0)
