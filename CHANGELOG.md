# to-be-released

## Changed

* Struct attributes can be overridden in a subclass (flash-gordon)

# v0.1.1 2016-11-13

## Fixed

* Make `Dry::Struct` act as a constrained type. This fixes the behavior of sum types containing structs (flash-gordon)

[Compare v0.1.0...v0.1.1](https://github.com/dry-rb/dry-struct/compare/v0.1.0...v0.1.1)

# v0.1.0 2016-09-21

## Added

* `:strict_with_defaults` constructor type (backus)

## Changed

* [BREAKING] `:strict` was renamed to `:permissive` as it ignores missing keys (backus)
* [BREAKING] `:strict` now raises on unexpected keys (backus)
* Structs no longer auto-register themselves in the types container as they implement `Type` interface and we don't have to wrap them in `Type::Definition` (flash-gordon)

[Compare v0.0.1...v0.1.0](https://github.com/dry-rb/dry-struct/compare/v0.0.1...v0.1.0)

# v0.0.1 2016-07-17

Initial release of code imported from dry-types
