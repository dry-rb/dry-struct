# frozen_string_literal: true

module Dry
  class Struct
    # A sum type of two or more structs
    # As opposed to Dry::Types::Sum::Constrained
    # this type tries no to coerce data first.
    class Sum < Dry::Types::Sum::Constrained
      def call(input)
        left.try_struct(input) do
          right.try_struct(input) { super }
        end
      end

      # @param [Hash{Symbol => Object},Dry::Struct] input
      # @yieldparam [Dry::Types::Result::Failure] failure
      # @yieldreturn [Dry::Types::Result]
      # @return [Dry::Types::Result]
      def try(input)
        if input.is_a?(Struct)
          ::Dry::Types::Result::Success.new(try_struct(input) { return super })
        else
          super
        end
      end

      # Build a new sum type
      # @param [Dry::Types::Type] type
      # @return [Dry::Types::Sum]
      def |(type)
        if (type.is_a?(::Class) && type <= Struct) || type.is_a?(Sum)
          Sum.new(self, type)
        else
          super
        end
      end

      # @return [boolean]
      def ===(value) = left === value || right === value

      protected

      # @private
      def try_struct(input, &block)
        left.try_struct(input) do
          right.try_struct(input, &block)
        end
      end
    end
  end
end
