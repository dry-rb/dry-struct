require 'dry/types/sum'
require 'dry/types/printer'

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
      # @yieldreturn [Dry::Types::ResultResult]
      # @return [Dry::Types::Result]
      def try(input)
        if input.is_a?(Struct)
          try_struct(input) { super }
        else
          super
        end
      end

      # Build a new sum type
      # @param [Dry::Types::Type] type
      # @return [Dry::Types::Sum]
      def |(type)
        if type.is_a?(Class) && type <= Struct || type.is_a?(Sum)
          Sum.new(self, type)
        else
          super
        end
      end

      # @return [boolean]
      def ===(value)
        left === value || right === value
      end

      protected

      # @private
      def try_struct(input)
        left.try_struct(input) do
          right.try_struct(input) { yield }
        end
      end
    end
  end
end
