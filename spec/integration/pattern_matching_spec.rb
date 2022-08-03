# frozen_string_literal: true

require "dry/monads"

RSpec.describe "pattern matching" do
  let(:struct) do
    Dry.Struct(
      first_name: "string",
      last_name: "string",
      address: Dry.Struct(
        city: "string",
        street: "string"
      ).tap { stub_const("Address", _1) }
    ).tap { stub_const("User", _1) }
  end

  let(:john) do
    struct.(
      first_name: "John",
      last_name: "Doe",
      address: {
        city: "Barcelona",
        street: "Carrer de Mallorca"
      }
    )
  end

  let(:jack) { john.new(first_name: "Jack") }

  let(:boris) do
    struct.(
      first_name: "Boris",
      last_name: "Johnson",
      address: {
        city: "London",
        street: "Downing street"
      }
    )
  end

  let(:alice) { john.new(first_name: "Alice") }

  let(:carol) { john.new(first_name: "Carol") }

  context "pattern matching" do
    def match(user)
      case user
      in User(first_name: "Jack")
        "It's Jack"
      in User(first_name: "Alice" | "Carol")
        "Alice or Carol"
      in User(first_name:, last_name: "Doe")
        "DOE, #{first_name.upcase}"
      in User(first_name:, last_name: "Doe")
        "DOE, #{first_name.upcase}"
      in User(first_name:, address: Address(street: "Downing street"))
        "PM is #{first_name}"
      end
    end

    specify do
      expect(match(john)).to eql("DOE, JOHN")
      expect(match(jack)).to eql("It's Jack")
      expect(match(boris)).to eql("PM is Boris")
      expect(match(alice)).to eql("Alice or Carol")
      expect(match(carol)).to eql("Alice or Carol")
    end

    example "collecting name" do
      case john
      in User(address: _, **name)
        expect(name).to eql(first_name: "John", last_name: "Doe")
      end
    end

    example "multiple structs" do
      case john
      in User(first_name: "John" | "Jack")
      end
    end
  end

  context "using with monads" do
    include Dry::Monads[:result, :maybe]

    let(:matching_context) do
      module Test
        class Operation
          include Dry::Monads[:result]

          def call(result)
            case result
            in Success(User(first_name:))
              "Name is #{first_name}"
            in Failure[:not_found]
              "Wasn't found"
            in Failure[error]
              "Error: #{error.inspect}, no meta given"
            in Failure[error, meta]
              "Error: #{error.inspect}, meta: #{meta.inspect}"
            end
          end
        end
      end
      Test::Operation
    end

    def match(result)
      matching_context.new.(result)
    end

    it "matches results" do
      expect(match(Success(john))).to eql("Name is John")
      expect(match(Success(boris))).to eql("Name is Boris")
      expect(match(Failure([:not_found]))).to eql("Wasn't found")
      expect(match(Failure([:not_valid]))).to eql("Error: :not_valid, no meta given")
      expect(match(Failure([:not_valid, name: "Too short"]))).to eql(
        'Error: :not_valid, meta: {:name=>"Too short"}'
      )
    end
  end
end
