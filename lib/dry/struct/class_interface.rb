require 'dry/core/class_attributes'
require 'dry/core/inflector'
require 'dry/equalizer'

require 'dry/struct/errors'
require 'dry/struct/constructor'

module Dry
  class Struct
    # Class-level interface of {Struct} and {Value}
    module ClassInterface
      include Core::ClassAttributes

      include Dry::Types::Type
      include Dry::Types::Builder

      # @param [Class] klass
      def inherited(klass)
        super

        base = self

        klass.class_eval do
          equalizer Equalizer.new(*schema.keys)
          include(klass.equalizer)

          @meta = base.meta
        end
      end

      # Adds an attribute for this {Struct} with given `name` and `type`
      # and modifies {.schema} accordingly.
      #
      # @param [Symbol] name name of the defined attribute
      # @param [Dry::Types::Definition, nil] type or superclass of nested type
      # @return [Dry::Struct]
      # @yield
      #   If a block is given, it will be evaluated in the context of
      #   a new struct class, and set as a nested type for the given
      #   attribute. A class with a matching name will also be defined for
      #   the nested type.
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      #
      # @example
      #   class Language < Dry::Struct
      #     attribute :name, Types::String
      #     attribute :details, Dry::Struct do
      #       attribute :type, Types::String
      #     end
      #   end
      #
      #   Language.schema
      #     #=> {
      #           :name=>#<Dry::Types::Definition primitive=String options={} meta={}>,
      #           :details=>Language::Details
      #         }
      #
      #   ruby = Language.new(name: 'Ruby', details: { type: 'OO' })
      #   ruby.name #=> 'Ruby'
      #   ruby.details #=> #<Language::Details type="OO">
      #   ruby.details.type #=> 'OO'
      def attribute(name, type = nil, &block)
        if block
          type = build_nested_type(name, type || ::Dry::Struct, &block)
        elsif type.nil?
          raise(
            ArgumentError,
            'you must supply a type or a block to `Dry::Struct.attribute`'
          )
        end

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

        schema schema.merge(new_schema)
        input Types['coercible.hash'].public_send(constructor_type, schema)

        new_schema.each_key do |key|
          attr_reader(key) unless instance_methods.include?(key)
        end

        equalizer.instance_variable_get('@keys').concat(new_schema.keys)
        @attribute_names = nil

        self
      end

      # @param [Symbol|String] name the name of the nested type
      # @param [Dry::Struct] superclass the superclass of the nested struct
      # @yield the body of the nested struct
      def build_nested_type(name, superclass, &block)
        type = Class.new(superclass, &block)
        const_name = Dry::Core::Inflector.camelize(name)

        raise(
          Struct::Error,
          "Can't create nested attribute - `#{self}::#{const_name}` already defined"
        ) if const_defined?(const_name)

        const_set(const_name, type)
      end
      private :build_nested_type

      # @param [Hash{Symbol => Dry::Types::Definition, Dry::Struct}] new_schema
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      def check_schema_duplication(new_schema)
        self_unique_keys = schema.keys - super_schema.keys
        conflicting_keys = new_schema.keys & self_unique_keys

        raise RepeatedAttributeError, conflicting_keys.first if conflicting_keys.any?
      end
      private :check_schema_duplication

      # @return [Hash{Symbol => Dry::Types::Definition, Dry::Struct}]
      def super_schema
        defined?(superclass.schema) ? superclass.schema : EMPTY_HASH
      end
      private :super_schema

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
      # the input back if it's a subclass of the struct.
      #
      # @param [Hash{Symbol => Object},Dry::Struct] attributes
      # @return [Dry::Struct]
      def call(attributes = default_attributes)
        return attributes if attributes.is_a?(self)
        new(attributes)
      end
      alias_method :[], :call

      # @param [#call,nil] constructor
      # @param [Hash] options
      # @param [#call,nil] block
      # @return [Dry::Struct::Constructor]
      def constructor(constructor = nil, **_options, &block)
        Struct::Constructor.new(self, fn: constructor || block)
      end

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
        result(::Dry::Types::Result::Failure, *args)
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

      # Checks if this {Struct} has the given attribute
      #
      # @param [Symbol] key Attribute name
      # @return [Boolean]
      def attribute?(key)
        schema.key?(key)
      end

      # Gets the list of attribute names
      #
      # @return [Array<Symbol>]
      def attribute_names
        @attribute_names ||= schema.keys
      end

      # @return [{Symbol => Object}]
      def meta(meta = Undefined)
        if meta.equal?(Undefined)
          @meta
        else
          Class.new(self) do
            @meta = @meta.merge(meta) unless meta.empty?
          end
        end
      end
    end
  end
end
