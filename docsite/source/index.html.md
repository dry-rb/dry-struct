---
title: Introduction
layout: gem-single
type: gem
name: dry-struct
sections:
 - nested-structs
 - recipes
---

`dry-struct` is a gem built on top of `dry-types` which provides virtus-like DSL for defining typed struct classes.

### Basic Usage

You can define struct objects which will have readers for specified attributes using a simple dsl:

``` ruby
require 'dry-struct'

module Types
  include Dry.Types()
end

class User < Dry::Struct
  attribute :name, Types::String.optional
  attribute :age, Types::Coercible::Integer
end

user = User.new(name: nil, age: '21')

user.name # nil
user.age # 21

user = User.new(name: 'Jane', age: '21')

user.name # => "Jane"
user.age # => 21
```

### Value

You can define value objects which will behave like structs but will be *deeply frozen*:

``` ruby
class Location < Dry::Struct::Value
  attribute :lat, Types::Float
  attribute :lng, Types::Float
end

loc1 = Location.new(lat: 1.23, lng: 4.56)
loc2 = Location.new(lat: 1.23, lng: 4.56)

loc1.frozen? # true
loc2.frozen? # true

loc1 == loc2
# true
```

### Hash Schemas

`Dry::Struct` out of the box uses [hash schemas](/gems/dry-types/1.0/hash-schemas) from `dry-types` for processing input hashes. `with_type_transform` and `with_key_transform` are exposed as `transform_types` and `transform_keys`:

```ruby
class User < Dry::Struct
  transform_keys(&:to_sym)

  attribute :name, Types::String.optional
  attribute :age, Types::Coercible::Integer
end

User.new('name' => 'Jane', 'age' => '21')
# => #<User name="Jane" age=21>
```

This plays nicely with inheritance, you can define a base struct for symbolizing input and then reuse it:

```ruby
class SymbolizeStruct < Dry::Struct
  transform_keys(&:to_sym)
end

class User < SymbolizeStruct
  attribute :name, Types::String.optional
  attribute :age, Types::Coercible::Integer
end
```

### Validating data with dry-struct

Please don't. Structs are meant to work with valid input, it cannot generate error messages good enough for displaying them for a user etc. Use [`dry-validation`](/gems/dry-validation) for validating incoming data and then pass its output to structs.

### Differences between dry-struct and virtus

`dry-struct` look somewhat similar to Virtus but there are few significant differences:

* Structs don't provide attribute writers and are meant to be used as "data objects" exclusively
* Handling of attribute values is provided by standalone type objects from `dry-types`, which gives you way more powerful features
* Handling of attribute hashes is provided by standalone hash schemas from `dry-types`, which means there are different types of constructors in `dry-struct`
* Structs are not designed as swiss-army knifes, specific constructor types are used depending on the use case
* Struct classes quack like `dry-types`, which means you can use them in hash schemas, as array members or sum them
