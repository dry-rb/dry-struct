require 'dry/core/class_attributes'
require 'dry/equalizer'

require 'dry/struct/errors'

module Dry
  class Struct
    # Class-level interface of {Struct} and {Value}
    module ClassInterface
      include Core::ClassAttributes

      include Dry::Types::Builder

      # @param [Module] base
      def self.extended(base)
        base.instance_variable_set(:@schema, EMPTY_HASH)
      end

      # @param [Class] klass
      def inherited(klass)
        super

        klass.instance_variable_set(:@schema, EMPTY_HASH)
        klass.equalizer Equalizer.new(*schema.keys)
        klass.send(:include, klass.equalizer)

        klass.attributes(EMPTY_HASH) unless equal?(Struct)
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
        input Types['coercible.hash'].public_send(constructor_type, schema)

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

      # @return [Hash{Symbol => Dry::Types::Definition, Dry::Struct}]
      def schema
        super_schema = superclass.respond_to?(:schema) ? superclass.schema : EMPTY_HASH
        super_schema.merge(@schema)
      end

      # @param [Hash{Symbol => Object},Dry::Struct] attributes
      # @raise [Struct::Error] if the given attributes don't conform {#schema}
      #   with given {#constructor_type}
      def new(attributes = default_attributes)
        if attributes.instance_of?(self)
          attributes
        else
          super(input[attributes])
        end
      rescue Types::SchemaError, Types::MissingKeyError, Types::UnknownKeysError => error
        raise Struct::Error, "[#{self}.new] #{error}"
      end

      # Calls type constructor. The behavior is identical to `.new` but returns
      # returns the input back if it's a subclass of the struct.
      #
      # @param [Hash{Symbol => Object},Dry::Struct] attributes
      # @return [Dry::Struct]
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
        check_invalid_schema_keys
        schema.each_with_object({}) { |(name, type), result|
          result[name] = type.evaluate if type.default?
        }
      end

      def check_invalid_schema_keys
        invalid_keys = schema.select { |name, type|  type.instance_of?(String) }
        raise ArgumentError, argument_error_msg(invalid_keys.keys) if invalid_keys.any?
      end

      def argument_error_msg(keys)
        "Invaild argument for #{keys.join(', ')}"
      end

      # @param [Hash{Symbol => Object}] input
      # @yieldparam [Dry::Types::Result::Failure] failure
      # @yieldreturn [Dry::Types::ResultResult]
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

      # @return [false]
      def default?
        false
      end

      # @param [Object, Dry::Struct] value
      # @return [Boolean]
      def valid?(value)
        self === value
      end

      # @return [true]
      def constrained?
        true
      end

      # @return [self]
      def primitive
        self
      end

      # @return [false]
      def optional?
        false
      end
    end
  end
end
