# frozen_string_literal: true

require "dry/types/printer"

module Dry
  module Types
    # @api private
    class Printer
      MAPPING[Struct::Sum] = :visit_struct_sum
      MAPPING[Struct::Constructor] = :visit_struct_constructor

      def visit_struct_sum(sum)
        visit_sum_constructors(sum) do |constructors|
          visit_options(EMPTY_HASH, sum.meta) do |opts|
            yield "Struct::Sum<#{constructors}#{opts}>"
          end
        end
      end

      alias_method :visit_struct_constructor, :visit_constructor
    end
  end
end
