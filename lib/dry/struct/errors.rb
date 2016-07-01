module Dry
  class Struct
    extend Dry::Configurable

    setting :namespace, self

    Error = Class.new(TypeError)

    class RepeatedAttributeError < ArgumentError
      def initialize(key)
        super("Attribute :#{key} has already been defined")
      end
    end
  end
end
