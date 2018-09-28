module Dry
  class Struct
    # Helper for {Struct#to_hash} implementation
    module Hashify
      # Converts value to hash recursively
      # @param [#to_hash, #map, Object] value
      # @return [Hash, Array]
      def self.[](value)
        if value.respond_to?(:to_hash)
          if RUBY_VERSION >= '2.4'
            value.to_hash.transform_values { |v| self[v] }
          else
            value.to_hash.each_with_object({}) { |(k, v), h| h[k] = self[v] }
          end
        elsif value.respond_to?(:to_ary)
          value.to_ary.map { |item| self[item] }
        else
          value
        end
      end
    end
  end
end
