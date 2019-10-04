---
title: Constructor Types (deprecated)
layout: gem-single
name: dry-struct
---

### Constructor types were removed in v0.5.0. Use `transform_types` and `transform_keys` as a replacement.

Your struct class can specify a constructor type, which uses [hash schemas](/gems/dry-types/hash-schemas-obsolete) to handle attributes in `.new` method. By default `:permissive` constructor is used.

To set a different constructor type simply use `constructor_type` setting:

``` ruby
class User < Dry::Struct
  constructor_type :strict

  attribute :name, Types::Strict::String
  attribute :age, Types::Strict::Integer
end

User.new(name: "Jane", age: 31)
# => #<User name="Jane" age=31>

User.new(name: "Jane", age: 31, unexpected: "attribute")
# Dry::Struct::Error: [User.new] unexpected keys [:unexpected] in Hash input

class Admin < Dry::Struct
  constructor_type :schema

  attribute :name, Types::Strict::String.default('John Doe')
  attribute :age, Types::Strict::Integer
end

Admin.new(name: "Jane")        #=> #<User name="Jane" age=nil>
Admin.new(age: 31)             #=> #<User name="John Doe" age=31>
Admin.new(name: nil, age: 31)  #=> #<User name="John Doe" age=31>
Admin.new(name: "Jane", age: 31, unexpected: "attribute")
  #=> #<User name="Jane" age=31>
```

Common constructor types include:

* `:permissive` - the default constructor type, useful for defining structs that are instantiated using data from the database (ie results of a database query), where you expect *all defined attributes to be present* and it's OK to ignore other keys (ie keys used for joining, that are not relevant from your domain structs point of view). Default values **are not used** otherwise you wouldn't notice missing data.
* `:schema` - missing keys will result in setting them using default values, unexpected keys will be ignored.
* `:strict` - useful when you *do not expect keys other than the ones you specified as attributes* in the input hash
* `:strict_with_defaults` - same as `:strict` but you are OK that some values may be nil and you want defaults to be set
* `:weak` and `:symbolized` - *don't use those with dry-struct*, and instead use dry-validation to process and validate attributes, otherwise your struct will behave as a data validator which raises exceptions on invalid input (assuming your attributes types are strict)
