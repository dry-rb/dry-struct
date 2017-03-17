# Symbolizes keys in a hash (at the top level, without nesting)

module Dry
  class Struct
    module SymbolizeKeys
      def self.[](value)
        return value unless value.respond_to?(:to_hash)
        value.to_hash.each_with_object({}) do |(key, val), hash|
          hash[key.to_sym] = val
        end
      end
    end
  end
end
