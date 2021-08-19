# frozen_string_literal: true

require "dry/struct"

module Dry
  class Struct
    # Allows modules to be treated structs ({Dry::Struct::Sum})
    # Calls on the module get dispatched to {Constructor#sum}
    # which is responsible for constructing a sum type consisting
    # of constants within the module. The module can be shared by
    # other constants as only the compatible types are selected
    #
    # @see [Struct.Union] for filtering and re-ordering options
    #
    # @example A module type of days of the week
    #   module Day
    #     include Dry::Struct::Union
    #
    #     class Monday < Dry::Struct
    #       attribute :id, Types.Value(:monday)
    #     end
    #
    #     class Tuesday < Dry::Struct
    #       attribute :id, Types.Value(:tuesday)
    #     end
    #
    #     # ...
    #   end
    #
    #   Day.name # => Day<[Monday | Tuesday | ...]>
    #   Day.call({ id: :monday }) # => Day::Monday
    module Union
      autoload :Constructor, "dry/struct/union/constructor"

      # @private
      def self.included(scope)
        super
        Union::Constructor.call(scope: scope)
      end
    end

    # @see [Dry::Struct::Union]
    #
    # Allows the dispach receiver, {Constructor#sum} to be configued
    # and re-ordered using {Union(exclude: [...], include: [...])}
    #
    # @option include: [Array<Symbol>] Constants to be included
    # @option exclude: [Array<Symbol>] Constants to be excluded
    # @raise [Dry::Struct::Error]
    # @return [Module]
    # @see [Union]
    # @example A module consisting of planets, except 'Pluto'
    #   module Planet
    #     include Dry::Struct::Union(exclude: 'Pluto')
    #
    #     class Earth < Dry::Struct
    #       attribute :id, Types.Value(:earth)
    #     end
    #
    #     class Pluto < Dry::Struct
    #       attribute :id, Types.Value(:pluto)
    #     end
    #
    #     class Mars < Dry::Struct
    #       attribute :id, Types.Value(:mars)
    #     end
    #   end
    #
    #   Planet.name # => Planet<[Earth | Mars]>
    #   Planet.call({ id: :mars }) # => Planet::Mars
    #   Planet.call({ id: :earth }) # => Planet::Earth
    #   Planet.call({ id: :pluto }) # => raises Dry::Struct::Error
    def self.Union(**options)
      Module.new do
        define_singleton_method(:included) do |scope|
          super(scope)
          Union::Constructor.call(scope: scope, **options)
        end
      end
    end
  end
end
