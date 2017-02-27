require 'dry-types'

require 'dry/struct/version'
require 'dry/struct/errors'
require 'dry/struct/class_interface'
require 'dry/struct/hashify'

module Dry
  class Struct
    extend ClassInterface

    constructor_type(:permissive)

    def initialize(attributes)
      attributes.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    def [](name)
      public_send(name)
    end

    def to_hash
      self.class.schema.keys.each_with_object({}) do |key, result|
        result[key] = Hashify[self[key]]
      end
    end
    alias_method :to_h, :to_hash
  end
end

require 'dry/struct/value'
