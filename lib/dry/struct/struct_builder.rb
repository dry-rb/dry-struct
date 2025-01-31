# frozen_string_literal: true

module Dry
  class Struct
    # @private
    class StructBuilder < Compiler
      attr_reader :struct

      def initialize(struct)
        super(Types)
        @struct = struct
      end

      # @param [Symbol|String] attr_name the name of the nested type
      # @param [Dry::Struct,Dry::Types::Type::Array,Undefined] type the superclass
      #                                                        of the nested struct
      # @yield the body of the nested struct
      def call(attr_name, type, &block)
        const_name = const_name(type, attr_name)
        check_name(const_name)

        builder = self
        parent = parent(type)

        new_type = ::Class.new(Undefined.default(parent, struct.abstract_class)) do
          if Undefined.equal?(parent)
            schema builder.struct.schema.clear
          end

          class_exec(&block)
        end

        struct.const_set(const_name, new_type)

        if array?(type)
          type.of(new_type)
        elsif optional?(type)
          new_type.optional
        else
          new_type
        end
      end

      private

      def type?(type) = type.is_a?(Types::Type)

      def array?(type)
        type?(type) && !type.optional? && type.primitive.equal?(::Array)
      end

      def optional?(type) = type?(type) && type.optional?

      def parent(type)
        if array?(type)
          visit(type.to_ast)
        elsif optional?(type)
          type.right
        else
          type
        end
      end

      def const_name(type, attr_name)
        snake_name =
          if array?(type)
            Core::Inflector.singularize(attr_name)
          else
            attr_name
          end

        Core::Inflector.camelize(snake_name)
      end

      def check_name(name)
        if struct.const_defined?(name, false)
          raise(
            Error,
            "Can't create nested attribute - `#{struct}::#{name}` already defined"
          )
        end
      end

      def visit_constrained(node)
        definition, * = node
        visit(definition)
      end

      def visit_array(node)
        member, * = node
        visit(member)
      end

      def visit_nominal(*) = Undefined

      def visit_constructor(node)
        definition, * = node
        visit(definition)
      end
    end
  end
end
