---
title: Recipes
layout: gem-single
name: dry-struct
---

### Symbolize input keys

```ruby
require 'dry-struct'

module Types
  include Dry.Types()
end

class User < Dry::Struct
  transform_keys(&:to_sym)

  attribute :name, Types::String
end

User.new('name' => 'Jane')
# => #<User name="Jane">
```

### Tolerance to extra keys

Structs ignore extra keys by default. This can be changed by replacing the constructor.

```ruby
class User < Dry::Struct
  # This does the trick
  schema schema.strict

  attribute :name, Types::String
end

User.new(name: 'Jane', age: 21)
# => Dry::Struct::Error ([User.new] unexpected keys [:age] in Hash input)
```

### Tolerance to missing keys

You can mark certain keys as optional by calling `attribute?`.

```ruby
class User < Dry::Struct
  attribute :name, Types::String
  attribute? :age, Types::Integer
end

user = User.new(name: 'Jane')
# => #<User name="Jane" age=nil>
user.age
# => nil
```

In the example above `nil` violates the type constraint so be careful with `attribute?`.

### Default values

Instead of violating constraints you can assign default values to attributes:

```ruby
class User < Dry::Struct
  attribute :name, Types::String
  attribute :age,  Types::Integer.default(18)
end

User.new(name: 'Jane')
# => #<User name="Jane" age=18>
```

### Resolving default values on `nil`

`nil` as a value isn't replaced with a default value for default types. You may use `transform_types` to turn all types into constructors which map `nil` to `Dry::Types::Undefined` which in order triggers default values.

```ruby
class User < Dry::Struct
  transform_types do |type|
    if type.default?
      type.constructor do |value|
        value.nil? ? Dry::Types::Undefined : value
      end
    else
      type
    end
  end

  attribute :name, Types::String
  attribute :age,  Types::Integer.default(18)
end

User.new(name: 'Jane')
# => #<User name="Jane" age=18>
User.new(name: 'Jane', age: nil)
# => #<User name="Jane" age=18>
```

### Creating a custom struct class

You can combine examples from this page to create a custom-purposed base struct class and the reuse it your application or gem

```ruby
class MyStruct < Dry::Struct
  # throw an error when unknown keys provided
  schema schema.strict

  # convert string keys to symbols
  transform_keys(&:to_sym)

  # resolve default types on nil
  transform_types do |type|
    if type.default?
      type.constructor do |value|
        value.nil? ? Dry::Types::Undefined : value
      end
    else
      type
    end
  end
end
```

### Set default value for a nested hash

```ruby
class Foo < Dry::Struct
  attribute :bar do
    attribute :nested, Types::Integer
  end
end
```

```ruby
class Foo < Dry::Struct
  class Bar < Dry::Struct
    attribute :nested, Types::Integer
  end

  attribute :bar, Bar.default { Bar.new(nested: 1) }
end
```

### Composing structs

You can compose other struct attributes as if they
had been defined in place.

```ruby
class Address < Dry::Struct
  attribute :city, Types::String
  attribute :country, Types::String
end

class User < Dry::Struct
  attribute :name, Types::String
  attributes_from Address
end

User.new(name: 'Quispe', city: 'La Paz', country: 'Bolivia')
```

Composition can happen within a nested attribute:

```ruby
class User < Dry::Struct
  attribute :name, Types::String
  attribute :address do
    attributes_from Address
  end
end
```
