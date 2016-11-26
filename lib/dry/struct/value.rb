require 'ice_nine'

module Dry
  class Struct
    # {Value} objects behave like {Struct}s but *deeply frozen*
    # using [`ice_nine`](https://github.com/dkubb/ice_nine)
    #
    # @example
    #   class Location < Dry::Struct::Value
    #     attribute :lat, Types::Strict::Float
    #     attribute :lng, Types::Strict::Float
    #   end
    #
    #   loc1 = Location.new(lat: 1.23, lng: 4.56)
    #   loc2 = Location.new(lat: 1.23, lng: 4.56)
    #
    #   loc1.frozen? #=> true
    #   loc2.frozen? #=> true
    #   loc1 == loc2 #=> true
    #
    # @see https://github.com/dkubb/ice_nine
    class Value < self
      # @param (see ClassInterface#new)
      # @return [Value]
      # @see https://github.com/dkubb/ice_nine
      def self.new(*)
        IceNine.deep_freeze(super)
      end
    end
  end
end
