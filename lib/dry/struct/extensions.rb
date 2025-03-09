# frozen_string_literal: true

Dry::Struct.register_extension(:pretty_print) do
  require "dry/struct/extensions/pretty_print"
end

Dry::Struct.register_extension(:super_diff) do
  require "dry/struct/extensions/super_diff"
end
