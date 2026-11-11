# frozen_string_literal: true

module Dry
  class Struct
    # Helper for {Struct#to_hash} implementation
    module Hashify
      # Classes of values with nothing to convert, checked first as they are the most common.
      LEAF_CLASSES = [
        ::String, ::Symbol, ::Integer, ::Float, ::NilClass, ::TrueClass, ::FalseClass, ::Time
      ].to_h { [_1, true] }.compare_by_identity.freeze
      private_constant :LEAF_CLASSES

      # Converts value to hash recursively
      # @param [#to_hash, #to_ary, Object] value
      # @return [Hash, Array]
      def self.[](value)
        if LEAF_CLASSES.key?(value.class)
          value
        elsif value.is_a?(::Dry::Struct)
          value.to_h
        elsif value.respond_to?(:to_hash)
          value.to_hash.transform_values { self[_1] }
        elsif value.respond_to?(:to_ary)
          value.to_ary.map { self[_1] }
        else
          value
        end
      end
    end
  end
end
