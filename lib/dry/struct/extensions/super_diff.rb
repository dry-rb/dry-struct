# frozen_string_literal: true

require "super_diff"
require "super_diff/rspec"

module Dry
  class Struct
    def attributes_for_super_diff = attributes
  end
end
