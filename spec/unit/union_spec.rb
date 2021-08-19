# frozen_string_literal: true

describe Dry::Struct::Union do
  context "given a union" do
    it "raises no error" do
      expect do
        Module.new do
          include Dry::Struct::Union
        end
      end.to_not raise_error
    end
  end

  context "given a class" do
    it "raises no error" do
      expect do
        Class.new do
          include Dry::Struct::Union
        end
      end.to_not raise_error
    end
  end

  describe "reopened module type" do
    let(:type) { Union::Reopen::Type }

    context "given [include ::Union] is added later" do
      context "given .call({})" do
        it "returns type" do
          expect(type.call({id: 2000})).to be_a(type::InnerA)
        end
      end
    end

    context "given a later struct" do
      context "given .call matching [A]" do
        it "returns A" do
          expect(type.call({id: 1000})).to be_a(type::InnerA)
        end
      end

      context "given .call matching [B]" do
        it "returns B" do
          expect(type.call({id: "string"})).to be_a(type::InnerB)
        end
      end

      context "given .call matching nothing" do
        it "raises error" do
          expect { type.call({id: nil}) }.to raise_error(Dry::Struct::Error)
        end
      end
    end
  end
end
