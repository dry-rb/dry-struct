# frozen_string_literal: true

require 'dry/types/compiler'

module Dry
  class Struct
    class Compiler < Types::Compiler
      def visit_struct(node)
        struct, _ = node

        struct
      end
    end
  end
end
