module Dry
  class Struct
    # Helper for {Struct#to_hash} implementation
    module Hashify
      # Converts value to hash recursively
      # @param [#to_hash, #map, Object] value
      # @return [Hash, Array]
      def self.[](value)
        if value.respond_to?(:to_hash)
          value.to_hash
        elsif value.respond_to?(:map)
          value.map { |item| self[item] }
        else
          value
        end
      end
    end
  end
end
