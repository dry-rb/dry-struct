# frozen_string_literal: true

RSpec.describe Dry::Struct::Constructor do
  include_context "user type"

  subject(:type) { Test::User.constructor(-> x { x }) }

  it_behaves_like Dry::Types::Nominal do
  end

  it "adds meta" do
    expect(type.meta(foo: :bar).meta).to eql(foo: :bar)
  end

  it "has .type equal to .primitive" do
    expect(type.type).to be(type.primitive)
  end

  describe "#optional" do
    let(:type) { super().optional }

    it "builds an optional type" do
      expect(type).to be_optional
      expect(type.(nil)).to be(nil)
    end
  end

  describe "#prepend" do
    let(:type) do
      super().prepend { |x| x.transform_keys(&:to_sym) }
    end

    specify do
      user = type.(
        "name" => "John",
        "age" => 20,
        "address" => {city: "London", zipcode: 123_123}
      )
      expect(user).to be_a(Test::User)
    end
  end

  context "wrapping constructors" do
    defaults = {
      age: 18,
      name: "John Doe"
    }

    subject(:type) do
      Test::User.constructor do |input, type|
        type.(input) { type.(defaults.merge(input)) }
      end
    end

    it "makes a seconds try with default values added" do
      expect(type.(address: {city: "London", zipcode: 123_123})).to be_a(Test::User)
    end

    it "has .type equal to .primitive" do
      expect(type.type).to be(type.primitive)
    end
  end
end
