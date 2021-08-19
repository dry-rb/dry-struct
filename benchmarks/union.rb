# frozen_string_literal: true

require "dry/struct/union"
require "benchmark/ips"
require "dry/types"

module Country
  include Dry::Struct.Union(include: %i[Scandinavia Germany])

  module Types
    include Dry::Types()
  end

  class Base < Dry::Struct
    abstract
  end

  module Scandinavia
    include Dry::Struct.Union(include: %i[Norway Sweden Denmark])

    class Base < Country::Base
      abstract
      attribute :trade, Types.Array(Scandinavia)
    end

    class Norway < Base
      attribute :id, Types.Value(:norway)
      HASH = {id: :norway, trade: []}.freeze
    end

    class Sweden < Base
      attribute :id, Types.Value(:sweden)
      HASH = {id: :sweden, trade: [Norway::HASH]}.freeze
    end

    class Denmark < Base
      attribute :id, Types.Value(:denmark)
      HASH = {id: :denmark, trade: [Sweden::HASH, Norway::HASH]}.freeze
    end

    HASHES = [Norway::HASH, Sweden::HASH, Denmark::HASH].freeze
  end

  class Germany < Base
    attribute :trade, Types.Array(Scandinavia)
    attribute :id, Types.Value(:germany)
    HASH = {id: :germany, trade: [Scandinavia::Denmark::HASH]}.freeze
  end

  HASHES = Scandinavia::HASHES + [Germany::HASH]
end

JOINED = [
  Country::Scandinavia::Norway,
  Country::Scandinavia::Sweden,
  Country::Scandinavia::Denmark,
  Country::Germany
].reduce(:|)

Benchmark.ips do |bm|
  bm.report("Struct::Union") do
    Country::HASHES.each do |hash|
      Country.call(hash)
    end
  end

  bm.report("Struct::Sum") do
    Country::HASHES.each do |hash|
      JOINED.call(hash)
    end
  end

  bm.compare!
end
