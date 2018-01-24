module Dry
  class Struct
    # Raised when given input doesn't conform schema and constructor type
    Error = Class.new(TypeError)

    # Raised when defining duplicate attributes
    class RepeatedAttributeError < ArgumentError
      # @param [Symbol] key
      #   attribute name that is the same as previously defined one
      def initialize(key)
        super("Attribute :#{key} has already been defined")
      end
    end

    # Raised when a struct doesn't have an attribute
    class MissingAttributeError < KeyError
      def initialize(key)
        super("Missing attribute: #{ key.inspect }")
      end
    end
  end
end
