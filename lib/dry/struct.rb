require 'dry-types'

require 'dry/struct/version'
require 'dry/struct/errors'
require 'dry/struct/class_interface'
require 'dry/struct/hashify'

module Dry
  # Typed {Struct} with virtus-like DSL for defining schema.
  #
  # ### Differences between dry-struct and virtus
  #
  # {Struct} look somewhat similar to [Virtus][] but there are few significant differences:
  #
  # * {Struct}s don't provide attribute writers and are meant to be used
  #   as "data objects" exclusively.
  # * Handling of attribute values is provided by standalone type objects from
  #   [`dry-types`][].
  # * Handling of attribute hashes is provided by standalone hash schemas from
  #   [`dry-types`][], which means there are different types of constructors in
  #   {Struct} (see {Dry::Struct::ClassInterface#constructor_type})
  # * Struct classes quack like [`dry-types`][], which means you can use them
  #   in hash schemas, as array members or sum them
  #
  # {Struct} class can specify a constructor type, which uses [hash schemas][]
  # to handle attributes in `.new` method.
  # See {ClassInterface#new} for constructor types descriptions and examples.
  #
  # [`dry-types`]: https://github.com/dry-rb/dry-types
  # [Virtus]: https://github.com/solnic/virtus
  # [hash schemas]: http://dry-rb.org/gems/dry-types/hash-schemas
  #
  # @example
  #   require 'dry-struct'
  #
  #   module Types
  #     include Dry::Types.module
  #   end
  #
  #   class Book < Dry::Struct
  #     attribute :title, Types::Strict::String
  #     attribute :subtitle, Types::Strict::String.optional
  #   end
  #
  #   rom_n_roda = Book.new(
  #     title: 'Web Development with ROM and Roda',
  #     subtitle: nil
  #   )
  #   rom_n_roda.title #=> 'Web Development with ROM and Roda'
  #   rom_n_roda.subtitle #=> nil
  #
  #   refactoring = Book.new(
  #     title: 'Refactoring',
  #     subtitle: 'Improving the Design of Existing Code'
  #   )
  #   refactoring.title #=> 'Refactoring'
  #   refactoring.subtitle #=> 'Improving the Design of Existing Code'
  class Struct
    extend ClassInterface

    # @overload constructor_type
    #   Returns the constructor type for {Struct}
    #   @return [Symbol] (:permissive)
    #   @see ClassInterface#constructor_type
    constructor_type(:permissive)

    # @param [Hash, #each] attributes
    def initialize(attributes)
      attributes.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    # Retrieves value of previously defined attribute by its' `name`
    #
    # @param [String] name
    # @return [Object]
    #
    # @example
    #   class Book < Dry::Struct
    #     attribute :title, Types::Strict::String
    #     attribute :subtitle, Types::Strict::String.optional
    #   end
    #
    #   rom_n_roda = Book.new(
    #     title: 'Web Development with ROM and Roda',
    #     subtitle: nil
    #   )
    #   rom_n_roda[:title] #=> 'Web Development with ROM and Roda'
    #   rom_n_roda[:subtitle] #=> nil
    def [](name)
      public_send(name)
    end

    # Converts the {Dry::Struct} to a hash with keys representing
    # each attribute (as symbols) and their corresponding values
    #
    # @return [Hash{Symbol => Object}]
    #
    # @example
    #   class Book < Dry::Struct
    #     attribute :title, Types::Strict::String
    #     attribute :subtitle, Types::Strict::String.optional
    #   end
    #
    #   rom_n_roda = Book.new(
    #     title: 'Web Development with ROM and Roda',
    #     subtitle: nil
    #   )
    #   rom_n_roda.to_hash
    #     #=> {title: 'Web Development with ROM and Roda', subtitle: nil}
    def to_hash
      self.class.schema.keys.each_with_object({}) do |key, result|
        result[key] = Hashify[self[key]]
      end
    end
    alias_method :to_h, :to_hash

    def new(changeset)
      self.class[to_hash.merge(changeset)]
    end
  end
end

require 'dry/struct/value'
