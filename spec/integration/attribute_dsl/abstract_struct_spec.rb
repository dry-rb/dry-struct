# frozen_string_literal: true

RSpec.describe Dry::Struct, method: '.abstract' do
  before do
    class Test::Abstract < Dry::Struct
      abstract

      transform_keys(&:to_sym)

      def key?(key)
        attributes.key?(key)
      end
    end
  end

  it 'is reused as a base class in descendants' do
    class Test::User < Test::Abstract
      attribute :name, 'string'

      attribute :address do
        attribute :city, 'string'
      end
    end

    user = Test::User.('name' => 'John', 'address' => { 'city' => 'Mexico' })

    expect(user.to_h).to eql(
      name: 'John',
      address: { city: 'Mexico' }
    )
    expect(Test::User::Address).to be < Test::Abstract
    expect(user.address.key?(:city)).to be(true)
    expect(user.address.key?(:street)).to be(false)
  end
end
