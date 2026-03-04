# frozen_string_literal: true

module Dry
  class Struct
    extend Core::Deprecations[:"dry-struct"]

    # {Value} objects behave like {Struct}s but *deeply frozen*
    # using `Ractor.make_shareable`
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
    class Value < self
      abstract

      # @param (see ClassInterface#new)
      # @return [Value]
      def self.new(*) = ::Ractor.make_shareable(super)
    end

    deprecate_constant :Value
  end
end
