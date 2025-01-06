# frozen_string_literal: true

RSpec.describe Dry::Types::Array do
  before do
    module Test
      class Street < Dry::Struct
        attribute :street_name, "string"
      end

      class City < Dry::Struct
        attribute :city_name, "string"
      end

      CityOrStreet = City | Street
    end
  end

  describe "#try" do
    context "simple struct" do
      subject(:array) { Dry::Types["array"].of(Test::Street) }
      it "returns success for valid array" do
        expect(array.try([{street_name: "Oxford"}, {street_name: "London"}])).to be_success
      end

      it "returns failure for invalid array" do
        expect(array.try([{name: "Oxford"}, {name: 123}])).to be_failure
        expect(array.try([{}])).to be_failure
      end
    end

    context "sum struct" do
      subject(:array) { Dry::Types["array"].of(Test::CityOrStreet) }

      it "returns success for valid array" do
        expect(array.try([{city_name: "London"}, {street_name: "Oxford"}])).to be_success
        expect(array.try([Test::Street.new(street_name: "Oxford")])).to be_success
      end

      it "returns failure for invalid array" do
        expect(array.try([{city_name: "London"}, {street_name: 123}])).to be_failure
      end
    end
  end
end
