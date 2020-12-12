# frozen_string_literal: true

RSpec.describe Dry::Struct::Constructor do
  include_context "user type"

  let(:type) { Test::User.constructor(-> x { x }) }

  it_behaves_like Dry::Types::Nominal do
  end

  it "adds meta" do
    expect(type.meta(foo: :bar).meta).to eql(foo: :bar)
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
      super().prepend { |x| x.map { |k, v| [k.to_sym, v] }.to_h }
    end

    specify do
      user = type.(
        "name" => "John",
        "age" => 20,
        "address" => { city: "London", zipcode: 123123 }
      )
      expect(user).to be_a(Test::User)
    end
  end
end
