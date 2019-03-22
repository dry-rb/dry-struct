# 0.7.0 2019-03-22

## Changed

* [BREAKING] `Struct.input` was renamed `Struct.schema`, hence `Struct.schema` returns an instance of `Dry::Types::Hash::Schema` rather than a `Hash`. Schemas are also implementing `Enumerable` but they iterate over key types.
  New API:
  ```ruby
  User.schema.each do |key|
    puts "Key name: #{ key.name }"
    puts "Key type: #{ key.type }"
  end
  ```
  To get a type by its name use `.key`:
  ```ruby
  User.schema.key(:id) # => #<Dry::Types::Hash::Key ...>
  ```
* [BREAKING] `transform_types` now passes one argument to the block, an instance of the `Key` type. Combined with the new API from dry-types it simplifies declaring omittable keys:
  ```ruby
  class StructWithOptionalKeys < Dry::Struct
    transform_types { |key| key.required(false) }
    # or simply
    transform_types(&:omittable)
  end
  ```
* `Dry::Stuct#new` is now more efficient for partial updates (flash-gordon)
* Ruby 2.3 is EOL and not officially supported. It may work but we don't test it.

[Compare v0.6.0...v0.7.0](https://github.com/dry-rb/dry-struct/compare/v0.6.0...v0.7.0)

# v0.6.0 2018-10-24

## Changed

* [BREAKING] `Struct.attribute?` in the old sense is deprecated, use `has_attribute?` as a replacement

## Added

* `Struct.attribute?` is an easy way to define omittable attributes (flash-gordon):

  ```ruby
  class User < Dry::Struct
    attribute  :name,  Types::Strict::String
    attribute? :email, Types::Strict::String
  end
  # User.new(name: 'John') # => #<User name="John">
  ```

## Fixed

* `Struct#to_h` recursively converts hash values to hashes, this was done to be consistent with current behavior for arrays (oeoeaio + ZimbiX)

[Compare v0.5.1...v0.6.0](https://github.com/dry-rb/dry-struct/compare/v0.5.1...v0.6.0)

# v0.5.1 2018-08-11

## Fixed

* Constant resolution is now restricted to the current module when structs are automatically defined using the block syntax. This shouldn't break any existing code (piktur)

## Added

* Pretty print extension (ojab)
  ```ruby
  Dry::Struct.load_extensions(:pretty_print)
  PP.pp(user)
  #<Test::User
   name="Jane",
   age=21,
   address=#<Test::Address city="NYC", zipcode="123">>
  ```

[Compare v0.5.0...v0.5.1](https://github.com/dry-rb/dry-struct/compare/v0.5.0...v0.5.1)

# v0.5.0 2018-05-03

## BREAKING CHANGES

* `constructor_type` was removed, use `transform_types` and `transform_keys` as a replacement (see below)
* Default types are evaluated _only_ on missing values. Again, use `tranform_types` as a work around for `nil`s
* Values are now stored within a single instance variable names `@attributes`, this sped up struct creation and improved support for reserved attribute names such as `hash`, they don't get a getter but still can be read via `#[]`
* Ruby 2.3 is a minimal supported version

## Added

* `Dry::Struct.transform_types` accepts a block which is yielded on every type to add. Since types are `dry-types`' objects that come with a robust DSL it's rather simple to restore the behavior of `constructor_type`. See https://github.com/dry-rb/dry-struct/pull/64 for details (flash-gordon)

  Example: evaluate defaults on `nil` values

  ```ruby
  class User < Dry::Struct
    transform_types do |type|
      type.constructor { |value| value.nil? ? Undefined : value  }
    end
  end
  ```

* `Data::Struct.transform_keys` accepts a block/proc that transforms keys of input hashes. The most obvious usage is simbolization but arbitrary transformations are allowed (flash-gordon)

* `Dry.Struct` builds a struct by a hash of attribute names and types (citizen428)

  ```ruby
  User = Dry::Struct(name: 'strict.string') do
    attribute :email, 'strict.string'
  end
  ```

* Support for `Struct.meta`, note that `.meta` returns a _new class_ (flash-gordon)

  ```ruby
  class User < Dry::Struct
    attribute :name, Dry::Types['strict.string']
  end

  UserWithMeta = User.meta(foo: :bar)

  User.new(name: 'Jade').class == UserWithMeta.new(name: 'Jade').class # => false
  ```

* `Struct.attribute` yields a block with definition for nested structs. It defines a nested constant for the new struct and supports arrays (AMHOL + flash-gordon)

  ```ruby
    class User < Dry::Struct
      attribute :name, Types::Strict::String
      attribute :address do
        attribute :country, Types::Strict::String
        attribute :city, Types::Strict::String
      end
      attribute :accounts, Types::Strict::Array do
        attribute :currency, Types::Strict::String
        attribute :balance, Types::Strict::Decimal
      end
    end

    # ^This automatically defines User::Address and User::Account
  ```

## Fixed

* Adding a new attribute invalidates `attribute_names` (flash-gordon)
* Struct classes track subclasses and define attributes in them, now it doesn't matter whether you define attributes first and _then_ subclass or vice versa. Note this can lead to memory leaks in Rails environment when struct classes are reloaded (flash-gordon)

[Compare v0.4.0...v0.5.0](https://github.com/dry-rb/dry-struct/compare/v0.4.0...v0.5.0)

# v0.4.0 2017-11-04

## Changed

* Attribute readers don't override existing instance methods (solnic)
* `Struct#new` uses raw attributes instead of method calls, this makes the behavior consistent with the change above (flash-gordon)
* `constructor_type` now actively rejects `:weak` and `:symbolized` values (GustavoCaso)

## Fixed

* `Struct#new` doesn't call `.to_hash` recursively (flash-gordon)

[Compare v0.3.1...v0.4.0](https://github.com/dry-rb/dry-struct/compare/v0.3.1...v0.4.0)

# v0.3.1 2017-06-30

## Added

* `Struct.constructor` that makes dry-struct more aligned with dry-types; now you can have a struct with a custom constructor that will be called _before_ calling the `new` method (v-kolesnikov)
* `Struct.attribute?` and `Struct.attribute_names` for introspecting struct attributes (flash-gordon)
* `Struct#__new__` is a safe-to-use-in-gems alias for `Struct#new` (flash-gordon)

[Compare v0.3.0...v0.3.1](https://github.com/dry-rb/dry-struct/compare/v0.3.0...v0.3.1)

# v0.3.0 2017-05-05

## Added

* `Dry::Struct#new` method to return new instance with applied changeset (Kukunin)

## Fixed

* `.[]` and `.call` does not coerce subclass to superclass anymore (Kukunin)
* Raise ArgumentError when attribute type is a string and no value provided is for `new` (GustavoCaso)

## Changed

* `.new` without arguments doesn't use nil as an input for non-default types anymore (flash-gordon)

[Compare v0.2.1...v0.3.0](https://github.com/dry-rb/dry-struct/compare/v0.2.1...v0.3.0)

# v0.2.1 2017-02-27

## Fixed

* Fixed `Dry::Struct::Value` which appeared to be broken in the last release (flash-gordon)

[Compare v0.2.0...v0.2.1](https://github.com/dry-rb/dry-struct/compare/v0.2.0...v0.2.1)

# v0.2.0 2016-02-26

## Changed

* Struct attributes can be overridden in a subclass (flash-gordon)

[Compare v0.1.1...v0.2.0](https://github.com/dry-rb/dry-struct/compare/v0.1.1...v0.2.0)

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
