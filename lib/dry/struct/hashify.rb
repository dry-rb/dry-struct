# frozen_string_literal: true

module Dry
  class Struct
    # Helper for {Struct#to_hash} implementation
    module Hashify
      # Converts value to hash recursively
      # @param [#to_hash, #map, Object] value
      # @return [Hash, Array]
      def self.[](value)
        if value.is_a?(Struct)
          value.to_h.transform_values { self[_1] }
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
