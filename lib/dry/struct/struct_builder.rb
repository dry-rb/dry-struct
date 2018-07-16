require 'dry/types/compiler'

module Dry
  class Struct
    # @private
    class StructBuilder < Dry::Types::Compiler
      attr_reader :struct

      def initialize(struct)
        super(Dry::Types)
        @struct = struct
      end

      # @param [Symbol|String] attr_name the name of the nested type
      # @param [Dry::Struct,Dry::Types::Type::Array] type the superclass of the nested struct
      # @yield the body of the nested struct
      def call(attr_name, type, &block)
        const_name = const_name(type, attr_name)
        check_name(const_name)

        new_type = Class.new(parent(type), &block)
        struct.const_set(const_name, new_type)

        if array?(type)
          type.of(new_type)
        else
          new_type
        end
      end

      private

      def array?(type)
        type.is_a?(Types::Type) && type.primitive.equal?(Array)
      end

      def parent(type)
        if array?(type)
          visit(type.to_ast)
        else
          type || default_superclass
        end
      end

      def default_superclass
        struct < Value ? Value : Struct
      end

      def const_name(type, attr_name)
        snake_name = if array?(type)
                       Dry::Core::Inflector.singularize(attr_name)
                     else
                       attr_name
                     end

        Dry::Core::Inflector.camelize(snake_name)
      end

      def check_name(name)
        raise(
          Struct::Error,
          "Can't create nested attribute - `#{struct}::#{name}` already defined"
        ) if struct.constants.include?(name.to_sym)
      end

      def visit_constrained(node)
        definition, * = node
        visit(definition)
      end

      def visit_array(node)
        member, * = node
        member
      end

      def visit_definition(*)
        default_superclass
      end

      def visit_constructor(node)
        definition, * = node
        visit(definition)
      end
    end
  end
end
