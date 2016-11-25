require 'dry/struct/errors'

module Dry
  class Struct
    # Class-level interface of {Struct} and {Value}
    module ClassInterface
      include Dry::Types::Builder

      # {Dry::Types::Hash} subclass with specific behaviour defined for
      # @return [Dry::Types::Hash]
      # @see #constructor_type
      attr_accessor :constructor

      # @return [Dry::Equalizer]
      attr_accessor :equalizer

      # @return [Symbol]
      # @see #constructor_type
      attr_writer :constructor_type

      protected :constructor=, :equalizer=, :constructor_type=

      # @param [Module] base
      def self.extended(base)
        base.instance_variable_set(:@schema, {})
      end

      # @param [Class] klass
      def inherited(klass)
        super

        klass.instance_variable_set(:@schema, {})
        klass.equalizer = Equalizer.new(*schema.keys)
        klass.constructor_type = constructor_type
        klass.send(:include, klass.equalizer)

        unless klass == Value
          klass.constructor = Types['coercible.hash']
        end

        klass.attributes({}) unless equal?(Struct)
      end

      # Adds an attribute for this {Struct} with given `name` and `type`
      # and modifies {.schema} accordingly.
      #
      # @param [Symbol] name name of the defined attribute
      # @param [Dry::Types::Definition] type
      # @return [Dry::Struct]
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      #
      # @example
      #   class Language < Dry::Struct
      #     attribute :name, Types::String
      #   end
      #
      #   Language.schema
      #     #=> {name: #<Dry::Types::Definition primitive=String options={}>}
      #
      #   ruby = Language.new(name: 'Ruby')
      #   ruby.name #=> 'Ruby'
      def attribute(name, type)
        attributes(name => type)
      end

      # @param [Hash{Symbol => Dry::Types::Definition}] new_schema
      # @return [Dry::Struct]
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      # @see #attribute
      # @example
      #   class Book1 < Dry::Struct
      #     attributes(
      #       title: Types::String,
      #       author: Types::String
      #     )
      #   end
      #
      #   Book.schema
      #     #=> {title: #<Dry::Types::Definition primitive=String options={}>,
      #     #    author: #<Dry::Types::Definition primitive=String options={}>}
      def attributes(new_schema)
        check_schema_duplication(new_schema)

        prev_schema = schema

        @schema = prev_schema.merge(new_schema)
        @constructor = Types['coercible.hash'].public_send(constructor_type, schema)

        attr_reader(*new_schema.keys)
        equalizer.instance_variable_get('@keys').concat(new_schema.keys)

        self
      end

      # @param [Hash{Symbol => Dry::Types::Definition, Dry::Struct}] new_schema
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      def check_schema_duplication(new_schema)
        shared_keys = new_schema.keys & (schema.keys - superclass.schema.keys)

        raise RepeatedAttributeError, shared_keys.first if shared_keys.any?
      end
      private :check_schema_duplication

      # Sets or retrieves {#constructor} type as a symbol
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
      # * `:weak` and `:symbolized` - *don't use those with {Struct}*,
      #   and instead use [`dry-validation`][] to process and validate
      #   attributes, otherwise your struct will behave as a data validator
      #   which raises exceptions on invalid input (assuming your attributes
      #   types are strict)
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
      # [`dry-validation`]: https://github.com/dry-rb/dry-validation
      #
      # @example `:permissive` constructor
      #   class User < Dry::Struct
      #     constructor_type :permissive
      #
      #     attribute :name, Types::Strict::String.default('John Doe')
      #     attribute :age, Types::Strict::Int
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
      #
      #     attribute :name, Types::Strict::String.default('John Doe')
      #     attribute :age, Types::Strict::Int
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
      #
      #     attribute :name, Types::Strict::String.default('John Doe')
      #     attribute :age, Types::Strict::Int
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
      #
      #     attribute :name, Types::Strict::String.default('John Doe')
      #     attribute :age, Types::Strict::Int
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
      def constructor_type(type = nil)
        if type
          @constructor_type = type
        else
          @constructor_type || :strict
        end
      end

      # @return [Hash{Symbol => Dry::Types::Definition, Dry::Struct}]
      def schema
        super_schema = superclass.respond_to?(:schema) ? superclass.schema : {}
        super_schema.merge(@schema)
      end

      # @param [Hash{Symbol => Object}] attributes
      # @raise [Struct::Error] if the given attributes don't conform {#schema}
      #   with given {#constructor_type}
      def new(attributes = default_attributes)
        if attributes.instance_of?(self)
          attributes
        else
          super(constructor[attributes])
        end
      rescue Types::SchemaError, Types::MissingKeyError, Types::UnknownKeysError => error
        raise Struct::Error, "[#{self}.new] #{error}"
      end

      def call(attributes = default_attributes)
        return attributes if attributes.is_a?(self)
        new(attributes)
      end
      alias_method :[], :call

      # Retrieves default attributes from defined {.schema}.
      # Used in a {Struct} constructor if no attributes provided to {.new}
      #
      # @return [Hash{Symbol => Object}]
      def default_attributes
        schema.each_with_object({}) { |(name, type), result|
          result[name] = type.default? ? type.evaluate : type[nil]
        }
      end

      # @param [Hash{Symbol => Object}] input
      # @return [Dry::Types::Result]
      def try(input)
        Types::Result::Success.new(self[input])
      rescue Struct::Error => e
        failure = Types::Result::Failure.new(input, e.message)
        block_given? ? yield(failure) : failure
      end

      # @param [({Symbol => Object})] args
      # @return [Dry::Types::Result::Success]
      def success(*args)
        result(Types::Result::Success, *args)
      end

      # @param [({Symbol => Object})] args
      # @return [Dry::Types::Result::Failure]
      def failure(*args)
        result(Types::Result::Failure, *args)
      end

      # @param [Class] klass
      # @param [({Symbol => Object})] args
      def result(klass, *args)
        klass.new(*args)
      end

      # @return [Boolean]
      def default?
        false
      end

      # @param [Object, Dry::Struct] value
      # @return [Boolean]
      def valid?(value)
        self === value
      end

      # @return [Boolean]
      def constrained?
        true
      end

      # @return [Dry::Struct]
      def primitive
        self
      end
    end
  end
end
