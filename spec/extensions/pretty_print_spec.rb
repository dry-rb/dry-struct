# frozen_string_literal: true

RSpec.describe Dry::Struct do
  describe "#pretty_inspect" do
    include_context "user type"

    subject(:pretty_inspect) { user.pretty_inspect }

    before { Dry::Struct.load_extensions(:pretty_print) }

    context "with Test::User" do
      let(:user) do
        user_type[
          name: "Jane", age: 21,
          address: {city: "NYC", zipcode: "123"}
        ]
      end

      it do
        is_expected.to eql <<~PRETTY_INSPECT
          #<Test::User
           name="Jane",
           age=21,
           address=#<Test::Address city="NYC", zipcode="123">>
        PRETTY_INSPECT
      end
    end

    context "with Test::SuperUSer" do
      let(:user) do
        root_type[
          name: :Mike, age: 43, root: false,
          address: {city: "Atlantis", zipcode: 456}
        ]
      end

      it do
        is_expected.to eql <<~PRETTY_INSPECT
          #<Test::SuperUser
           name="Mike",
           age=43,
           root=false,
           address=#<Test::Address city="Atlantis", zipcode="456">>
        PRETTY_INSPECT
      end
    end
  end
end
