# frozen_string_literal: true

RSpec.describe Dry::Struct::Sum do
  before do
    module Test
      class Street < Dry::Struct
        attribute :name, "strict.string"
      end

      class City < Dry::Struct
        attribute :name, "strict.string"
      end

      class Region < Dry::Struct
        attribute :name, "strict.string"
      end

      class Highway < Street
      end
    end
  end

  subject(:sum) { Test::Street | Test::City | Test::Region }

  let(:street) { Test::Street.new(name: "Oxford") }
  let(:city) { Test::City.new(name: "London") }
  let(:england) { Test::Region.new(name: "England") }
  let(:highway) { Test::Highway.new(name: "Ratcliffe") }

  it "is constructed from two structs via |" do
    expect(Test::Street | Test::City).to be_a(Dry::Struct::Sum)
  end

  describe "#call" do
    it "first checks for type w/o coercing to hash" do
      expect(sum.(city)).to be_a(Test::City)
      expect(sum.(england)).to be_a(Test::Region)
    end

    it "works with hashes" do
      expect(sum.(name: "Baker")).to eql(Test::Street.new(name: "Baker"))
    end

    it "works with subclasses" do
      expect(sum.(highway)).to be(highway)
    end
  end

  describe "#optional?" do
    specify do
      expect(sum).not_to be_optional
    end
  end

  describe "#===" do
    it "recursively checks types without coercion" do
      # rubocop:disable Style/NilComparison
      expect(sum === nil).to be(false)
      expect((Dry::Struct | Dry::Struct) === nil).to be(false)
      # rubocop:enable Style/NilComparison
    end
  end
end
