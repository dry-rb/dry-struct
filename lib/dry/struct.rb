require 'dry-types'

require 'dry/struct/version'
require 'dry/struct/errors'
require 'dry/struct/class_interface'
require 'dry/struct/hashify'

module Dry
  # Typed {Struct} with virtus-like DSL for defining schema.
  #
  # ### Differences between dry-struct and virtus
  #
  # {Struct} look somewhat similar to [Virtus][] but there are few significant differences:
  #
  # * {Struct}s don't provide attribute writers and are meant to be used
  #   as "data objects" exclusively.
  # * Handling of attribute values is provided by standalone type objects from
  #   [`dry-types`][].
  # * Handling of attribute hashes is provided by standalone hash schemas from
  #   [`dry-types`][], which means there are different types of constructors in
  #   {Struct} (see {Dry::Struct::ClassInterface#constructor_type})
  # * Struct classes quack like [`dry-types`][], which means you can use them
  #   in hash schemas, as array members or sum them
  #
  # {Struct} class can specify a constructor type, which uses [hash schemas][]
  # to handle attributes in `.new` method.
  # See {ClassInterface#new} for constructor types descriptions and examples.
  #
  # [`dry-types`]: https://github.com/dry-rb/dry-types
  # [Virtus]: https://github.com/solnic/virtus
  # [hash schemas]: http://dry-rb.org/gems/dry-types/hash-schemas
  #
  # @example
  #   require 'dry-struct'
  #
  #   module Types
  #     include Dry::Types.module
  #   end
  #
  #   class Book < Dry::Struct
  #     attribute :title, Types::Strict::String
  #     attribute :subtitle, Types::Strict::String.optional
  #   end
  #
  #   rom_n_roda = Book.new(
  #     title: 'Web Development with ROM and Roda',
  #     subtitle: nil
  #   )
  #   rom_n_roda.title #=> 'Web Development with ROM and Roda'
  #   rom_n_roda.subtitle #=> nil
  #
  #   refactoring = Book.new(
  #     title: 'Refactoring',
  #     subtitle: 'Improving the Design of Existing Code'
  #   )
  #   refactoring.title #=> 'Refactoring'
  #   refactoring.subtitle #=> 'Improving the Design of Existing Code'
  class Struct
    extend ClassInterface

    # {Dry::Types::Hash} subclass with specific behaviour defined for
    # @return [Dry::Types::Hash]
    # @see #constructor_type
    defines :input
    input Types['coercible.hash']

    # Sets or retrieves {#constructor} type as a symbol
    #
    # @note All examples below assume that you have defined {Struct} with
    #   following attributes and explicitly call only {#constructor_type}:
    #
    #   ```ruby
    #   class User < Dry::Struct
    #     attribute :name, Types::Strict::String.default('John Doe')
    #     attribute :age, Types::Strict::Int
    #   end
    #   ```
    #
    # ### Common constructor types include:
    #
    # * `:permissive` - the default constructor type, useful for defining
    #   {Struct}s that are instantiated using data from the database
    #   (i.e. results of a database query), where you expect *all defined
    #   attributes to be present* and it's OK to ignore other keys
    #   (i.e. keys used for joining, that are not relevant from your domain
    #   {Struct}s point of view). Default values **are not used** otherwise
    #   you wouldn't notice missing data.
    # * `:schema` - missing keys will result in setting them using default
    #   values, unexpected keys will be ignored.
    # * `:strict` - useful when you *do not expect keys other than the ones
    #   you specified as attributes* in the input hash
    # * `:strict_with_defaults` - same as `:strict` but you are OK that some
    #   values may be nil and you want defaults to be set
    #
    # To feel the difference between constructor types, look into examples.
    # Each of them provide the same attributes' definitions,
    # different constructor type, and 4 cases of given input:
    #
    # 1. Input omits a key for a value that does not have a default
    # 2. Input omits a key for a value that has a default
    # 3. Input contains nil for a value that specifies a default
    # 4. Input includes a key that was not specified in the schema
    #
    # @note Don’t use `:weak` and `:symbolized` as {#constructor_type},
    #   and instead use [`dry-validation`][] to process and validate
    #   attributes, otherwise your struct will behave as a data validator
    #   which raises exceptions on invalid input (assuming your attributes
    #   types are strict)
    #   [`dry-validation`]: https://github.com/dry-rb/dry-validation
    #
    # @example `:permissive` constructor
    #   class User < Dry::Struct
    #     constructor_type :permissive
    #   end
    #
    #   User.new(name: "Jane")
    #     #=> Dry::Struct::Error: [User.new] :age is missing in Hash input
    #   User.new(age: 31)
    #     #=> Dry::Struct::Error: [User.new] :name is missing in Hash input
    #   User.new(name: nil, age: 31)
    #     #=> #<User name="John Doe" age=31>
    #   User.new(name: "Jane", age: 31, unexpected: "attribute")
    #     #=> #<User name="Jane" age=31>
    #
    # @example `:schema` constructor
    #   class User < Dry::Struct
    #     constructor_type :schema
    #   end
    #
    #   User.new(name: "Jane")        #=> #<User name="Jane" age=nil>
    #   User.new(age: 31)             #=> #<User name="John Doe" age=31>
    #   User.new(name: nil, age: 31)  #=> #<User name="John Doe" age=31>
    #   User.new(name: "Jane", age: 31, unexpected: "attribute")
    #     #=> #<User name="Jane" age=31>
    #
    # @example `:strict` constructor
    #   class User < Dry::Struct
    #     constructor_type :strict
    #   end
    #
    #   User.new(name: "Jane")
    #     #=> Dry::Struct::Error: [User.new] :age is missing in Hash input
    #   User.new(age: 31)
    #     #=> Dry::Struct::Error: [User.new] :name is missing in Hash input
    #   User.new(name: nil, age: 31)
    #     #=> Dry::Struct::Error: [User.new] nil (NilClass) has invalid type for :name
    #   User.new(name: "Jane", age: 31, unexpected: "attribute")
    #     #=> Dry::Struct::Error: [User.new] unexpected keys [:unexpected] in Hash input
    #
    # @example `:strict_with_defaults` constructor
    #   class User < Dry::Struct
    #     constructor_type :strict_with_defaults
    #   end
    #
    #   User.new(name: "Jane")
    #     #=> Dry::Struct::Error: [User.new] :age is missing in Hash input
    #   User.new(age: 31)
    #     #=> #<User name="John Doe" age=31>
    #   User.new(name: nil, age: 31)
    #     #=> Dry::Struct::Error: [User.new] nil (NilClass) has invalid type for :name
    #   User.new(name: "Jane", age: 31, unexpected: "attribute")
    #     #=> Dry::Struct::Error: [User.new] unexpected keys [:unexpected] in Hash input
    #
    # @see http://dry-rb.org/gems/dry-types/hash-schemas
    #
    # @overload constructor_type(type)
    #   Sets the constructor type for {Struct}
    #   @param [Symbol] type one of constructor types, see above
    #   @return [Symbol]
    #
    # @overload constructor_type
    #   Returns the constructor type for {Struct}
    #   @return [Symbol] (:strict)
    defines :constructor_type
    constructor_type :permissive

    # @return [Dry::Equalizer]
    defines :equalizer

    # @param [Hash, #each] attributes
    def initialize(attributes)
      attributes.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    # Retrieves value of previously defined attribute by its' `name`
    #
    # @param [String] name
    # @return [Object]
    #
    # @example
    #   class Book < Dry::Struct
    #     attribute :title, Types::Strict::String
    #     attribute :subtitle, Types::Strict::String.optional
    #   end
    #
    #   rom_n_roda = Book.new(
    #     title: 'Web Development with ROM and Roda',
    #     subtitle: nil
    #   )
    #   rom_n_roda[:title] #=> 'Web Development with ROM and Roda'
    #   rom_n_roda[:subtitle] #=> nil
    def [](name)
      public_send(name)
    end

    # Converts the {Dry::Struct} to a hash with keys representing
    # each attribute (as symbols) and their corresponding values
    #
    # @return [Hash{Symbol => Object}]
    #
    # @example
    #   class Book < Dry::Struct
    #     attribute :title, Types::Strict::String
    #     attribute :subtitle, Types::Strict::String.optional
    #   end
    #
    #   rom_n_roda = Book.new(
    #     title: 'Web Development with ROM and Roda',
    #     subtitle: nil
    #   )
    #   rom_n_roda.to_hash
    #     #=> {title: 'Web Development with ROM and Roda', subtitle: nil}
    def to_hash
      self.class.schema.keys.each_with_object({}) do |key, result|
        result[key] = Hashify[self[key]]
      end
    end
    alias_method :to_h, :to_hash

    def new(changeset)
      self.class[to_hash.merge(changeset)]
    end
  end
end

require 'dry/struct/value'
