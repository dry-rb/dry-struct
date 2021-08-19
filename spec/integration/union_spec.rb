# frozen_string_literal: true

RSpec.describe Dry::Struct::Union do
  module Solar
    class Base < Dry::Struct
      abstract
      schema schema.strict
    end

    module Types
      include Dry::Types()
    end

    module Weather
      include Dry::Struct.Union(include: [:Warm])
      MAX_TEMP = 274

      class Base < Solar::Base
        abstract
        attribute :temp, "integer"
      end

      class Cold < Base
        attribute :id, Types.Value(:cold)
      end

      class Warm < Base
        attribute :id, Types.Value(:warm)
      end
    end

    module Season
      include Dry::Struct::Union

      class Spring < Solar::Base
        attribute :id, Types.Value(:spring)
      end

      module Unused
        class Autum < Solar::Base
          attribute :id, Types.Value(:autum)
        end
      end
    end

    module Planet
      include Dry::Struct.Union(exclude: :Pluto)

      class Base < Solar::Base
        abstract
        attribute? :closest, Planet
        attribute? :season, Season
        attribute? :weather, Weather
      end

      class Pluto < Base
        attribute :id, Types.Value(:pluto)
      end

      class Earth < Base
        attribute :id, Types.Value(:earth)
      end

      class Mars < Base
        attribute :id, Types.Value(:mars)
      end
    end
  end

  describe Solar do
    let(:remove) { "" }
    let(:cold) { {id: :cold, temp: 100} }
    let(:warm) { {id: :warm, temp: 100} }
    let(:spring) { {id: :spring} }

    describe described_class::Weather do
      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Solar::Weather<[#{remove}Solar::Weather::Warm]>") }
      end

      describe ".call" do
        describe "Warm" do
          subject { described_class.call(warm) }
          it { is_expected.to be_a(described_class::Warm) }
        end

        describe "Cold" do
          it "throws an error" do
            expect do
              described_class.call(cold)
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end

    describe described_class::Planet do
      let(:earth) { {id: :earth, weather: warm, season: spring} }
      let(:mars) { {id: :mars, closest: earth, weather: warm} }

      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Solar::Planet<[#{remove}Solar::Planet::Earth | #{remove}Solar::Planet::Mars]>") }
      end

      describe ".call" do
        describe "Mars" do
          subject { described_class.call(mars) }
          it { is_expected.to be_a(described_class::Mars) }
          it { is_expected.to have_attributes(to_h: mars) }
        end

        describe "Earth" do
          subject { described_class.call(earth) }
          it { is_expected.to be_a(described_class::Earth) }
          it { is_expected.to have_attributes(to_h: earth) }
        end

        describe "Pluto" do
          it "throws an error" do
            expect do
              described_class.call({id: :pluto})
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end

    describe described_class::Season do
      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Solar::Season<[#{remove}Solar::Season::Spring]>") }
      end

      describe ".call" do
        describe "Spring" do
          subject { described_class.call(spring) }
          it { is_expected.to be_a(described_class::Spring) }
        end

        describe "Autum" do
          it "throws an error" do
            expect do
              described_class.call({id: :autum})
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end
  end

  describe "edge cases" do
    subject { self.class::Type }

    describe ".call" do
      context "given an empty type union" do
        subject do
          Module.new do
            include Dry::Struct::Union
          end
        end

        it { is_expected.to have_attributes(__types__: []) }
      end

      context "given a type module with nothing excluded" do
        module self::Type
          include Dry::Struct::Union

          class A < Dry::Struct
            # NOP
          end
        end

        subject { self.class::Type }
        it { is_expected.to have_attributes(__types__: [self.class::Type::A]) }
      end
    end
  end
end
