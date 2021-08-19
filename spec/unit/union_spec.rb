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
    let(:type) { self.class::Type }

    context "given [include ::Union] is added later" do
      module self::Type
        # NOP
      end

      module self::Type
        include Dry::Struct::Union

        class Inner < Dry::Struct
          # NOP
        end
      end

      context "given .call({})" do
        it "returns type" do
          expect(type.call({})).to be_a(type::Inner)
        end
      end
    end

    context "given a later struct" do
      module self::Type
        include Dry::Struct::Union

        class InnerA < Dry::Struct
          attribute :id, "integer"
        end
      end

      module self::Type
        class InnerB < Dry::Struct
          attribute :id, "string"
        end
      end

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
