# frozen_string_literal: true

RSpec.describe "Dry::Struct.attributes_from" do
  it "composes attributes at place" do
    module Test
      class Address < Dry::Struct
        attribute :city, "string"
        attribute :zipcode, "coercible.string"
      end

      class User < Dry::Struct
        attribute :name, "coercible.string"
        attributes_from Address
        attribute :age, "coercible.integer"
      end
    end

    expect(Test::User.attribute_names).to eql(
      [:name, :city, :zipcode, :age]
    )
  end

  it "composes within a nested attribute" do
    module Test
      class Address < Dry::Struct
        attribute :city, "string"
        attribute :zipcode, "coercible.string"
      end

      class User < Dry::Struct
        attribute :address do
          attributes_from Address
        end
      end
    end

    expect(Test::User.schema.key(:address).attribute_names).to eql(
      [:city, :zipcode]
    )
  end

  it "composes a nested attribute" do
    module Test
      class Address < Dry::Struct
        attribute :address do
          attribute :city, "string"
          attribute :zipcode, "coercible.string"
        end
      end

      class User < Dry::Struct
        attributes_from Address
      end
    end

    expect(Test::User.schema.key(:address).attribute_names).to eql(
      [:city, :zipcode]
    )
  end

  context "behavior" do
    before do
      module Test
        class Address < Dry::Struct
          attribute :address do
            attribute :city, "string"
            attribute :zipcode, "coercible.string"
          end
        end

        class User < Dry::Struct
          attributes_from Address
        end
      end
    end

    let(:user) { Test::User.new(address: {city: "NYC", zipcode: 123}) }

    it "adds accessors" do
      expect(user.address.city).to eql("NYC")
    end

    it "resets attribute names" do
      expect(Test::User.attribute_names).to eql(%i[address])
    end

    context "when attribute name is not a valid method name" do
      before do
        module Test
          class InvalidName < Dry::Struct
            attribute :"123", "string"
            attribute :":", "string"
            attribute :"with space", "string"
            attribute :"with-dash", "string"
          end
        end
      end

      it "adds an accessor" do
        odd_struct = Test::InvalidName.new(
          "123": "John",
          ":": "Jane",
          "with space": "Doe",
          "with-dash": "Smith"
        )
        expect(odd_struct.public_send(:"123")).to eql("John")
        expect(odd_struct.public_send(:":")).to eql("Jane")
        expect(odd_struct.public_send("with space")).to eql("Doe")
        expect(odd_struct.public_send("with-dash")).to eql("Smith")
      end
    end

    context "inheritance" do
      before do
        class Test::Person < Dry::Struct
        end

        class Test::Citizen < Test::Person
        end

        Test::Person.attributes_from(Test::Address)
      end

      let(:citizen) { Test::Citizen.new(user.to_h) }

      it "adds attributes to subclasses" do
        expect(citizen.address.city).to eql("NYC")
      end
    end

    context "omittable keys" do
      before do
        module Test
          class Address
            attribute? :country, "string"
          end

          class Person < Dry::Struct
            attributes_from Address
          end
        end
      end

      let(:person_without_country) { Test::Person.new(user.to_h) }

      let(:person_with_country) do
        Test::Person.new(
          country: "uk",
          address: {
            city: "London",
            zipcode: 234
          }
        )
      end

      it "adds omittable keys" do
        expect(person_without_country.country).to be_nil
        expect(person_with_country.country).to eql("uk")
      end
    end
  end
end
