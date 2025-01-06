# frozen_string_literal: true

module Dry
  class Struct
    # Raised when given input doesn't conform schema and constructor type
    Error = Class.new(::Dry::Types::CoercionError)

    # Raised when defining duplicate attributes
    class RepeatedAttributeError < ::ArgumentError
      # @param [Symbol] key
      #   attribute name that is the same as previously defined one
      def initialize(key)
        super("Attribute :#{key} has already been defined")
      end
    end

    # Raised when a struct doesn't have an attribute
    class MissingAttributeError < ::KeyError
      def initialize(attribute:, klass:)
        super("Missing attribute: #{attribute.inspect} on #{klass}")
      end
    end

    # When struct class stored in ast was garbage collected because no alive objects exists
    # This shouldn't happen in a working application
    class RecycledStructError < ::RuntimeError
      def initialize
        super("Reference to struct class was garbage collected")
      end
    end
  end
end
