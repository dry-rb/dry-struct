# frozen_string_literal: true

RSpec.describe Dry::Struct::Value do
  before do
    module Test
      class Address < Dry::Struct::Value
        attribute :city, 'strict.string'
        attribute :zipcode, 'coercible.string'
      end

      class User < Dry::Struct::Value
        attribute :name, 'coercible.string'
        attribute :age, 'coercible.integer'
        attribute :address, Test::Address
      end

      class SuperUser < User
        attributes(root: 'strict.bool')
      end
    end
  end

  it_behaves_like Dry::Struct do
    subject(:type) { Test::SuperUser }
  end

  it 'is deeply frozen' do
    address = Test::Address.new(city: 'NYC', zipcode: 123)
    expect(address).to be_frozen
    expect(address.city).to be_frozen
  end
end
