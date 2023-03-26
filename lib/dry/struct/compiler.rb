# frozen_string_literal: true

module Dry
  class Struct
    class Compiler < Types::Compiler
      def visit_struct(node)
        struct, _ = node

        struct.__getobj__
      rescue ::WeakRef::RefError
        if struct.weakref_alive?
          raise
        else
          raise RecycledStructError
        end
      end
    end
  end
end
