# frozen_string_literal: true

require "ice_nine"

module Dry
  class Struct
    extend Core::Deprecations[:"dry-struct"]

    # {Value} objects behave like {Struct}s but *deeply frozen*
    # using [`ice_nine`](https://github.com/dkubb/ice_nine)
    #
    # @example
    #   class Location < Dry::Struct::Value
    #     attribute :lat, Types::Float
    #     attribute :lng, Types::Float
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
      abstract

      # @param (see ClassInterface#new)
      # @return [Value]
      # @see https://github.com/dkubb/ice_nine
      def self.new(*) = ::IceNine.deep_freeze(super)
    end

    deprecate_constant :Value
  end
end
