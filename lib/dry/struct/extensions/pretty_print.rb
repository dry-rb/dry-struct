# frozen_string_literal: true

require "pp" # rubocop:disable Lint/RedundantRequireStatement

module Dry
  class Struct
    def pretty_print(pp)
      klass = self.class
      pp.group(1, "#<#{klass.name || klass.inspect}", ">") do
        pp.seplist(@attributes.keys, proc { pp.text "," }) do |column_name|
          column_value = @attributes[column_name]
          pp.breakable " "
          pp.group(1) do
            pp.text column_name.to_s
            pp.text "="
            pp.pp column_value
          end
        end
      end
    end
  end
end
