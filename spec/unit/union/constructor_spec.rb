# frozen_string_literal: true

describe Dry::Struct::Union::Constructor do
  describe ".new" do
    let(:error) { Dry::Struct::Error }

    let(:type) do
      Module.new do
        include Dry::Struct::Union
      end
    end

    let(:params) do
      {scope: type}
    end

    describe "scope:" do
      context "given a union type" do
        let(:type) do
          Module.new do
            include Dry::Struct::Union
          end
        end

        it "raises no error" do
          expect { described_class.new(**params, scope: type) }.not_to raise_error
        end
      end
    end

    describe "include:" do
      context "given a non-existing constant" do
        it "raises error" do
          expect { described_class.new(**params, include: ["DoesNotExist"]).sum.call({}) }.to raise_error(Dry::Struct::Error)
        end
      end

      describe "array" do
        context "given an empty list" do
          it "raises error" do
            expect { described_class.new(**params, include: []) }.to raise_error(error)
          end
        end

        context "given not :include" do
          let(:params) { super().merge(include: nil).compact }

          it "raises no error" do
            expect { described_class.new(**params) }.not_to raise_error
          end
        end

        context "given [Symbol]" do
          it "raises no error" do
            expect { described_class.new(**params, include: [:Object]) }.not_to raise_error
          end
        end

        context "given a number" do
          it "raises error" do
            expect { described_class.new(**params, include: [10]) }.to raise_error(error)
          end
        end

        context "given a [String]" do
          it "raises no error" do
            expect { described_class.new(**params, include: ["Object"]) }.not_to raise_error
          end
        end
      end

      describe "value" do
        context "given a [String]" do
          it "raises no error" do
            expect { described_class.new(**params, include: "Object") }.not_to raise_error
          end
        end

        context "given a number" do
          it "raises error" do
            expect { described_class.new(**params, include: 10) }.to raise_error(error)
          end
        end
      end
    end

    describe "exclude:" do
      context "given a non-existing constant" do
        it "raises error" do
          expect { described_class.new(**params, exclude: ["DoesNotExist"]).sum.call({}) }.to raise_error(Dry::Types::CoercionError)
        end
      end

      describe "array" do
        context "given an empty list" do
          it "raises no error" do
            expect { described_class.new(**params, exclude: []) }.not_to raise_error
          end
        end

        context "given not :exclude" do
          let(:params) { super().merge(exclude: nil).compact }

          it "raises no error" do
            expect { described_class.new(**params) }.not_to raise_error
          end
        end

        context "given [Symbol]" do
          it "raises no error" do
            expect { described_class.new(**params, exclude: [:Object]) }.not_to raise_error
          end
        end

        context "given a number" do
          it "raises error" do
            expect { described_class.new(**params, exclude: [10]) }.to raise_error(error)
          end
        end

        context "given a [String]" do
          it "raises no error" do
            expect { described_class.new(**params, exclude: ["Object"]) }.not_to raise_error
          end
        end
      end

      describe "value" do
        context "given a [String]" do
          it "raises no error" do
            expect { described_class.new(**params, exclude: "Object") }.not_to raise_error
          end
        end

        context "given a number" do
          it "raises error" do
            expect { described_class.new(**params, exclude: 10) }.to raise_error(error)
          end
        end
      end
    end
  end
end
