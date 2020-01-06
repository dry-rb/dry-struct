# frozen_string_literal: true

module Dry
  class Struct
    class Constructor
      include Dry::Equalizer(:type)
      include Dry::Types::Type

      # @return [#call]
      attr_reader :fn

      # @return [#call]
      attr_reader :type

      # @param [Struct] type
      # @param [Hash] options
      # @param [#call, nil] block
      def initialize(type, options = {}, &block)
        @type = type
        @fn = options.fetch(:fn, block)
      end

      # @param [Object] input
      # @return [Object]
      def call(input)
        type[fn[input]]
      end
      alias_method :[], :call
    end
  end
end
