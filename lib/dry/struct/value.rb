require 'ice_nine'

require 'dry/struct'

module Dry
  class Struct
    class Value < self
      def self.new(*)
        IceNine.deep_freeze(super)
      end
    end
  end
end
