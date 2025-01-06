# frozen_string_literal: true

require "weakref"

module Dry
  class Struct
    # Class-level interface of {Struct} and {Value}
    module ClassInterface # rubocop:disable Metrics/ModuleLength
      include Core::ClassAttributes

      include Types::Type
      include Types::Builder

      # Adds an attribute for this {Struct} with given `name` and `type`
      # and modifies {.schema} accordingly.
      #
      # @param [Symbol] name name of the defined attribute
      # @param [Dry::Types::Type, nil] type or superclass of nested type
      # @return [Dry::Struct]
      # @yield
      #   If a block is given, it will be evaluated in the context of
      #   a new struct class, and set as a nested type for the given
      #   attribute. A class with a matching name will also be defined for
      #   the nested type.
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      #
      # @example with nested structs
      #   class Language < Dry::Struct
      #     attribute :name, Types::String
      #     attribute :details, Dry::Struct do
      #       attribute :type, Types::String
      #     end
      #   end
      #
      #   Language.schema # new lines for readability
      #   # => #<Dry::Types[
      #           Constructor<Schema<keys={
      #             name: Constrained<Nominal<String> rule=[type?(String)]>
      #             details: Language::Details
      #           }> fn=Kernel.Hash>]>
      #
      #   ruby = Language.new(name: 'Ruby', details: { type: 'OO' })
      #   ruby.name #=> 'Ruby'
      #   ruby.details #=> #<Language::Details type="OO">
      #   ruby.details.type #=> 'OO'
      #
      # @example with a nested array of structs
      #   class Language < Dry::Struct
      #     attribute :name, Types::String
      #     attribute :versions, Types::Array.of(Types::String)
      #     attribute :celebrities, Types::Array.of(Dry::Struct) do
      #       attribute :name, Types::String
      #       attribute :pseudonym, Types::String
      #     end
      #   end
      #
      #   Language.schema # new lines for readability
      #   => #<Dry::Types[Constructor<Schema<keys={
      #         name: Constrained<Nominal<String> rule=[type?(String)]>
      #         versions: Constrained<
      #                     Array<Constrained<Nominal<String> rule=[type?(String)]>
      #                   > rule=[type?(Array)]>
      #         celebrities: Constrained<Array<Language::Celebrity> rule=[type?(Array)]>
      #      }> fn=Kernel.Hash>]>
      #
      #   ruby = Language.new(
      #     name: 'Ruby',
      #     versions: %w(1.8.7 1.9.8 2.0.1),
      #     celebrities: [
      #       { name: 'Yukihiro Matsumoto', pseudonym: 'Matz' },
      #       { name: 'Aaron Patterson', pseudonym: 'tenderlove' }
      #     ]
      #   )
      #   ruby.name #=> 'Ruby'
      #   ruby.versions #=> ['1.8.7', '1.9.8', '2.0.1']
      #   ruby.celebrities
      #     #=> [
      #           #<Language::Celebrity name='Yukihiro Matsumoto' pseudonym='Matz'>,
      #           #<Language::Celebrity name='Aaron Patterson' pseudonym='tenderlove'>
      #         ]
      #   ruby.celebrities[0].name #=> 'Yukihiro Matsumoto'
      #   ruby.celebrities[0].pseudonym #=> 'Matz'
      #   ruby.celebrities[1].name #=> 'Aaron Patterson'
      #   ruby.celebrities[1].pseudonym #=> 'tenderlove'
      def attribute(name, type = Undefined, &)
        attributes(name => build_type(name, type, &))
      end

      # Add atributes from another struct
      #
      # @example
      #   class Address < Dry::Struct
      #     attribute :city, Types::String
      #     attribute :country, Types::String
      #   end
      #
      #   class User < Dry::Struct
      #     attribute :name, Types::String
      #     attributes_from Address
      #   end
      #
      #   User.new(name: 'Quispe', city: 'La Paz', country: 'Bolivia')
      #
      # @example with nested structs
      #   class User < Dry::Struct
      #     attribute :name, Types::String
      #     attribute :address do
      #       attributes_from Address
      #     end
      #   end
      #
      # @param struct [Dry::Struct]
      def attributes_from(struct)
        extracted_schema = struct.schema.keys.to_h do |key|
          if key.required?
            [key.name, key.type]
          else
            [:"#{key.name}?", key.type]
          end
        end
        attributes(extracted_schema)
      end

      # Adds an omittable (key is not required on initialization) attribute for this {Struct}
      #
      # @example
      #   class User < Dry::Struct
      #     attribute  :name,  Types::String
      #     attribute? :email, Types::String
      #   end
      #
      #   User.new(name: 'John') # => #<User name="John" email=nil>
      #
      # @param [Symbol] name name of the defined attribute
      # @param [Dry::Types::Type, nil] type or superclass of nested type
      # @return [Dry::Struct]
      #
      def attribute?(*args, &)
        if args.size == 1 && !block_given?
          Core::Deprecations.warn(
            "Dry::Struct.attribute? is deprecated for checking attribute presence, " \
            "use has_attribute? instead",
            tag: :"dry-struct"
          )

          has_attribute?(args[0])
        else
          name, * = args

          attribute(:"#{name}?", build_type(*args, &))
        end
      end

      # @param [Hash{Symbol => Dry::Types::Type}] new_schema
      # @return [Dry::Struct]
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      # @see #attribute
      # @example
      #   class Book < Dry::Struct
      #     attributes(
      #       title: Types::String,
      #       author: Types::String
      #     )
      #   end
      #
      #   Book.schema
      #   # => #<Dry::Types[Constructor<Schema<keys={
      #   #      title: Constrained<Nominal<String> rule=[type?(String)]>
      #   #      author: Constrained<Nominal<String> rule=[type?(String)]>
      #   #    }> fn=Kernel.Hash>]>
      def attributes(new_schema)
        keys = new_schema.keys.map { |k| k.to_s.chomp("?").to_sym }
        check_schema_duplication(keys)

        schema schema.schema(new_schema)

        define_accessors(keys)

        @attribute_names = nil

        subclasses.each do |d|
          inherited_attrs = new_schema.reject { |k, _| d.has_attribute?(k.to_s.chomp("?").to_sym) }
          d.attributes(inherited_attrs)
        end

        self
      end

      # Add an arbitrary transformation for new attribute types.
      #
      # @param [#call,nil] proc
      # @param [#call,nil] block
      # @example
      #   class Book < Dry::Struct
      #     transform_types { |t| t.meta(struct: :Book) }
      #
      #     attribute :title, Types::String
      #   end
      #
      #   Book.schema.key(:title).meta # => { struct: :Book }
      #
      def transform_types(proc = nil, &block)
        schema schema.with_type_transform(proc || block)
      end

      # Add an arbitrary transformation for input hash keys.
      #
      # @param [#call,nil] proc
      # @param [#call,nil] block
      # @example
      #   class Book < Dry::Struct
      #     transform_keys(&:to_sym)
      #
      #     attribute :title, Types::String
      #   end
      #
      #   Book.new('title' => "The Old Man and the Sea")
      #   # => #<Book title="The Old Man and the Sea">
      def transform_keys(proc = nil, &block)
        schema schema.with_key_transform(proc || block)
      end

      # @param [Hash{Symbol => Dry::Types::Type, Dry::Struct}] new_keys
      # @raise [RepeatedAttributeError] when trying to define attribute with the
      #   same name as previously defined one
      def check_schema_duplication(new_keys)
        overlapping_keys = new_keys & (attribute_names - superclass.attribute_names)

        if overlapping_keys.any?
          raise RepeatedAttributeError, overlapping_keys.first
        end
      end
      private :check_schema_duplication

      # @param [Hash{Symbol => Object},Dry::Struct] attributes
      # @raise [Struct::Error] if the given attributes don't conform {#schema}
      def new(attributes = default_attributes, safe = false, &) # rubocop:disable Style/OptionalBooleanParameter
        if attributes.is_a?(Struct)
          if equal?(attributes.class)
            attributes
          else
            # This implicit coercion is arguable but makes sense overall
            # in cases there you pass child struct to the base struct constructor
            # User.new(super_user)
            #
            # We may deprecate this behavior in future forcing people to be explicit
            new(attributes.to_h, safe, &)
          end
        elsif safe
          load(schema.call_safe(attributes) { |output = attributes| return yield output })
        else
          load(schema.call_unsafe(attributes))
        end
      rescue Types::CoercionError => e
        raise Error, "[#{self}.new] #{e}", e.backtrace
      end

      # @api private
      def call_safe(input, &)
        if input.is_a?(self)
          input
        else
          new(input, true, &)
        end
      end

      # @api private
      def call_unsafe(input)
        if input.is_a?(self)
          input
        else
          new(input)
        end
      end

      # @api private
      def load(attributes)
        struct = allocate
        struct.__send__(:initialize, attributes)
        struct
      end

      # @param [#call,nil] constructor
      # @param [#call,nil] block
      # @return [Dry::Struct::Constructor]
      def constructor(constructor = nil, **, &block)
        Constructor[self, fn: constructor || block]
      end

      # @param [Hash{Symbol => Object},Dry::Struct] input
      # @yieldparam [Dry::Types::Result::Failure] failure
      # @yieldreturn [Dry::Types::Result]
      # @return [Dry::Types::Result]
      def try(input)
        success(self[input])
      rescue Error => e
        failure_result = failure(input, e)
        block_given? ? yield(failure_result) : failure_result
      end

      # @param [Hash{Symbol => Object},Dry::Struct] input
      # @return [Dry::Types::Result]
      # @private
      def try_struct(input)
        if input.is_a?(self)
          input
        else
          yield
        end
      end

      # @param [({Symbol => Object})] args
      # @return [Dry::Types::Result::Success]
      def success(*args) = result(Types::Result::Success, *args)

      # @param [({Symbol => Object})] args
      # @return [Dry::Types::Result::Failure]
      def failure(*args) = result(Types::Result::Failure, *args)

      # @param [Class] klass
      # @param [({Symbol => Object})] args
      def result(klass, *args) = klass.new(*args)

      # @return [false]
      def default? = false

      # @param [Object, Dry::Struct] other
      # @return [Boolean]
      def ===(other) = other.is_a?(self)
      alias_method :primitive?, :===

      # @return [true]
      def constrained? = true

      # @return [self]
      def primitive = self

      # @return [false]
      def optional? = false

      # @return [Proc]
      def to_proc
        @to_proc ||= proc { |input| call(input) }
      end

      # Checks if this {Struct} has the given attribute
      #
      # @param [Symbol] key Attribute name
      # @return [Boolean]
      def has_attribute?(key) = schema.key?(key)

      # Gets the list of attribute names
      #
      # @return [Array<Symbol>]
      def attribute_names
        @attribute_names ||= schema.map(&:name)
      end

      # @return [{Symbol => Object}]
      def meta(meta = Undefined)
        if meta.equal?(Undefined)
          schema.meta
        elsif meta.empty?
          self
        else
          ::Class.new(self) do
            schema schema.meta(meta) unless meta.empty?
          end
        end
      end

      # Build a sum type
      # @param [Dry::Types::Type] type
      # @return [Dry::Types::Sum]
      def |(type)
        if type.is_a?(::Class) && type <= Struct
          Sum.new(self, type)
        else
          super
        end
      end

      # Make the struct abstract. This class will be used as a default
      # parent class for nested structs
      def abstract
        abstract_class self
      end

      # Dump to the AST
      #
      # @return [Array]
      #
      # @api public
      def to_ast(meta: true)
        [:struct, [::WeakRef.new(self), schema.to_ast(meta: meta)]]
      end

      # Stores an object for building nested struct classes
      # @return [StructBuilder]
      def struct_builder
        @struct_builder ||= StructBuilder.new(self).freeze
      end
      private :struct_builder

      # Retrieves default attributes from defined {.schema}.
      # Used in a {Struct} constructor if no attributes provided to {.new}
      #
      # @return [Hash{Symbol => Object}]
      def default_attributes(default_schema = schema)
        default_schema.each_with_object({}) do |key, result|
          result[key.name] = default_attributes(key.schema) if struct?(key.type)
        end
      end
      private :default_attributes

      # Checks if the given type is a Dry::Struct
      #
      # @param [Dry::Types::Type] type
      # @return [Boolean]
      def struct?(type)
        type.is_a?(::Class) && type <= Struct
      end
      private :struct?

      # Constructs a type
      #
      # @return [Dry::Types::Type, Dry::Struct]
      def build_type(name, type = Undefined, &)
        type_object =
          if type.is_a?(::String)
            Types[type]
          elsif !block_given? && Undefined.equal?(type)
            raise(
              ::ArgumentError,
              "you must supply a type or a block to `Dry::Struct.attribute`"
            )
          else
            type
          end

        if block_given?
          struct_builder.(name, type_object, &)
        else
          type_object
        end
      end
      private :build_type

      # @api private
      def define_accessors(keys)
        (keys - instance_methods).each do |key|
          if valid_method_name?(key)
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def #{key}                      # def email
                @attributes[#{key.inspect}]   #   @attributes[:email]
              end                             # end
            RUBY
          else
            define_method(key) { @attributes[key] }
          end
        end
      end
      private :define_accessors

      # @api private
      private def valid_method_name?(key) = key.to_s.match?(/\A[a-zA-Z_]\w*\z/)
    end
  end
end
