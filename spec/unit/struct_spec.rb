
# frozen_string_literal: true

require "dry/struct"

RSpec.describe Dry::Struct do
  describe ".to_ast" do
    let(:address) do
      Dry.Struct(street: "string", city?: "optional.string")
    end

    example "simple AST" do
      expect(address.to_ast).to eql(
        [
          :struct,
          [address, address.schema.to_ast]
        ]
      )
    end

    context "with meta" do
      let(:address) { super().meta(foo: :bar) }

      specify "on" do
        expect(address.to_ast).to eql(
          [
            :struct,
            [address, address.schema.to_ast(meta: true)]
          ]
        )
      end

      specify "off" do
        expect(address.to_ast(meta: false)).to eql(
          [
            :struct,
            [address, address.schema.to_ast(meta: false)]
          ]
        )
      end
    end
  end
end
