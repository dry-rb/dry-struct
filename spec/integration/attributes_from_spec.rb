# frozen_string_literal: true

RSpec.describe 'Dry::Struct.attributes_from' do
  it 'composes attributes at place' do
    module Test
      class Address < Dry::Struct
        attribute :city, 'string'
        attribute :zipcode, 'coercible.string'
      end

      class User < Dry::Struct
        attribute :name, 'coercible.string'
        attributes_from Address
        attribute :age, 'coercible.integer'
      end
    end

    expect(Test::User.attribute_names).to eq(
      [:name, :city, :zipcode, :age]
    )
  end

  it 'composes within a nested attribute' do
    module Test
      class Address < Dry::Struct
        attribute :city, 'string'
        attribute :zipcode, 'coercible.string'
      end

      class User < Dry::Struct
        attribute :address do
          attributes_from Address
        end
      end
    end

    expect(Test::User.schema.key(:address).attribute_names).to eq(
      [:city, :zipcode]
    )
  end

  it 'composes a nested attribute' do
    module Test
      class Address < Dry::Struct
        attribute :address do
          attribute :city, 'string'
          attribute :zipcode, 'coercible.string'
        end
      end

      class User < Dry::Struct
        attributes_from Address
      end
    end

    expect(Test::User.schema.key(:address).attribute_names).to eq(
      [:city, :zipcode]
    )
  end
end
