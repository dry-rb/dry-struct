# frozen_string_literal: true

require "ice_nine" if RUBY_ENGINE != "ruby"

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
      def self.new(*)
        obj = super
        if defined?(::Ractor)
          ::Ractor.make_shareable(obj)
        elsif defined?(::IceNine)
          ::IceNine.deep_freeze(obj)
        else
          obj.freeze
        end
      end
    end

    deprecate_constant :Value
  end
end
