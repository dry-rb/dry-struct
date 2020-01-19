# frozen_string_literal: true

module Dry
  class Struct
    class Constructor < Types::Constructor
      alias_method :primitive, :type
    end
  end
end
