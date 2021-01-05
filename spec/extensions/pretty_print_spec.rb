# frozen_string_literal: true

RSpec.describe Dry::Struct do
  describe "#pretty_print" do
    include_context "user type"

    before { Dry::Struct.load_extensions(:pretty_print) }

    let(:string_io) { StringIO.new(String.new) }
    subject(:actual) do
      string_io.rewind
      string_io.read
    end
    before { PP.pp(user, string_io) }

    describe "#pretty_print" do
      context "with Test::User" do
        let(:user) do
          user_type[
            name: "Jane", age: 21,
            address: {city: "NYC", zipcode: "123"}
          ]
        end

        it do
          should eql <<~PRETTY_PRINT
            #<Test::User
             name="Jane",
             age=21,
             address=#<Test::Address city="NYC", zipcode="123">>
          PRETTY_PRINT
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
          should eql <<~PRETTY_PRINT
            #<Test::SuperUser
             name="Mike",
             age=43,
             root=false,
             address=#<Test::Address city="Atlantis", zipcode="456">>
          PRETTY_PRINT
        end
      end
    end
  end
end
