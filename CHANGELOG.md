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
