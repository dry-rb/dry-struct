# frozen_string_literal: true

require "dry/struct"

module Dry
  class Struct
    module Union
      # Used to identify compatible types without manual dispatching
      # Extend this module with a refinment to introduce new types
      #
      # @see [Constructor#types]
      # @example Introduce {Dry::Types::Type} as a compatible type
      #  refine Dry::Types::Type do
      #    def constructor?
      #      true
      #    end
      #  end
      # @private
      module Extensions
        refine Dry::Struct.singleton_class do
          # True for non-abstract structs
          #
          # @return [Boolean]
          def constructor?
            abstract_class != self
          end
        end

        refine BasicObject do
          # Fallback implementation for incompatible objects
          #
          # @return [Boolean]
          def constructor?
            false
          end
        end
      end
    end
  end
end
