---
title: Nested Structs
layout: gem-single
name: dry-struct
---

The DSL allows to define nested structs by passing a block to `attribute`:

```ruby
class User < Dry::Struct
  attribute :name, Types::String
  attribute :address do
    attribute :city,   Types::String
    attribute :street, Types::String
  end
end

User.new(name: 'Jane', address: { city: 'London', street: 'Oxford' })
# => #<User name="Jane" address=#<User::Address city="London" street="Oxford">>

# constants for nested structs are automatically defined
User::Address
# => User::Address
```

By default, new struct classes uses `Dry::Struct` as a base class (`Dry::Struct::Value` for values). You can explicitly pass a different class:

```ruby
class User < Dry::Struct
  attribute :address, MyStruct do
    # ...
  end
end
```

It is even possible to define an array of struct:

```ruby
class User < Dry::Struct
  attribute :addresses, Types::Array do
    attribute :city,   Types::String
    attribute :street, Types::String
  end
end

# constants are still there!
User::Address
# => User::Address
```
