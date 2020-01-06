# frozen_string_literal: true

require_relative 'setup'

ATTR_NAMES = [:attr0, :attr1, :attr2, :attr3, :attr4, :attr5, :attr6, :attr7, :attr8, :attr9]

class Integers < Dry::Struct
  ATTR_NAMES.each do |name|
    attribute? name, 'coercible.integer'
  end
end

integers = {attr0: 0, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5, attr6: 6, attr7: 7, attr8: 8, attr9: 9}

require 'pry-byebug'

profile do
  1_000_000.times do
    Integers.new(integers)
  end
end
