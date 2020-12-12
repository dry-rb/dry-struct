# frozen_string_literal: true

RSpec.shared_context "user type" do
  let(:user_type) { Test::User }
  let(:root_type) { Test::SuperUser }

  before do
    module Test
      class BaseAddress < Dry::Struct
        attribute :street, "string"
      end

      class Address < Dry::Struct
        attribute :city, "string"
        attribute :zipcode, "coercible.string"
      end

      # This abstract user guarantees User preserves schema definition
      class AbstractUser < Dry::Struct
        attribute :name, "coercible.string"
        attribute :age, "coercible.integer"
        attribute :address, Test::Address
      end

      class User < AbstractUser
      end

      class SuperUser < User
        attributes(root: "bool")
      end
    end
  end
end
