# frozen_string_literal: true

RSpec.describe Dry::Struct, method: ".attribute" do
  include_context "user type"

  def assert_valid_struct(user)
    expect(user.name).to eql("Jane")
    expect(user.age).to be(21)
    expect(user.address.city).to eql("NYC")
    expect(user.address.zipcode).to eql("123")
  end

  context "when given a pre-defined nested type" do
    it "defines attributes for the constructor" do
      user = user_type[
        name: :Jane, age: "21", address: {city: "NYC", zipcode: 123}
      ]

      assert_valid_struct(user)
    end
  end

  context "when given a block-style nested type" do
    context "when the nested type is already defined" do
      context "with no superclass type" do
        let(:user_type) do
          Class.new(Dry::Struct) do
            attribute :name, "coercible.string"
            attribute :age, "coercible.integer"
            attribute :address do
              attribute :city, "strict.string"
              attribute :zipcode, "coercible.string"
            end
          end
        end

        it "defines attributes for the constructor" do
          user = user_type[
            name: :Jane, age: "21", address: {city: "NYC", zipcode: 123}
          ]

          assert_valid_struct(user)
        end

        it "defines a nested type" do
          expect { user_type.const_get("Address") }.to_not raise_error
        end
      end

      context "with a superclass type" do
        let(:user_type) do
          Class.new(Dry::Struct) do
            attribute :name, "coercible.string"
            attribute :age, "coercible.integer"
            attribute :address, Test::BaseAddress do
              attribute :city, "string"
              attribute :zipcode, "coercible.string"
            end
          end
        end

        it "defines attributes for the constructor" do
          user = user_type[
            name: :Jane, age: "21", address: {
              street: "123 Fake Street",
              city: "NYC",
              zipcode: 123
            }
          ]

          assert_valid_struct(user)
          expect(user.address.street).to eq("123 Fake Street")
        end

        it "defines a nested type" do
          expect { user_type.const_get("Address") }.to_not raise_error
        end
      end
    end

    context "when the nested type is not defined" do
      let(:struct) { Class.new(Dry::Struct) }

      it "should check constant existence within class scope only" do
        expect { struct.attribute(:test) { attribute(:abc, "string") } }.not_to raise_error
      end
    end

    context "when the nested type is already defined" do
      before do
        module Test
          module AlreadyDefined
            class User < Dry::Struct
              class Address
              end
            end
          end
        end
      end

      it "raises a Dry::Struct::Error" do
        expect {
          Test::AlreadyDefined::User.attribute(:address) {}
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  context "when no nested attribute block given" do
    it "raises error when type is missing" do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar
        end
      }.to raise_error(ArgumentError)
    end
  end

  context "when nested attribute block given" do
    it "does not raise error when type is missing" do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar do
            attribute :foo, "strict.string"
          end
        end
      }.to_not raise_error
    end
  end

  it "ignores unknown keys" do
    user = user_type[
      name: :Jane, age: "21", address: {city: "NYC", zipcode: 123}, invalid: "foo"
    ]

    assert_valid_struct(user)
  end

  it "merges attributes from the parent struct" do
    user = root_type[
      name: :Jane, age: "21", root: true, address: {city: "NYC", zipcode: 123}
    ]

    assert_valid_struct(user)

    expect(user.root).to be(true)
  end

  it "raises error when attribute is defined twice" do
    expect {
      class Test::Foo < Dry::Struct
        attribute :bar, "strict.string"
        attribute :bar, "strict.string"
      end
    }.to raise_error(
      Dry::Struct::RepeatedAttributeError,
      "Attribute :bar has already been defined"
    )
  end

  it "allows to redefine attributes in a subclass" do
    expect {
      class Test::Foo < Dry::Struct
        attribute :bar, "strict.string"
      end

      class Test::Bar < Test::Foo
        attribute :bar, "strict.integer"
      end
    }.not_to raise_error
  end

  it "can be chained" do
    class Test::Foo < Dry::Struct
    end

    Test::Foo
      .attribute(:foo, "strict.string")
      .attribute(:bar, "strict.integer")

    foo = Test::Foo.new(foo: "foo", bar: 123)

    expect(foo.foo).to eql("foo")
    expect(foo.bar).to eql(123)
  end

  it "doesn't define readers if methods are present" do
    class Test::Foo < Dry::Struct
      def age
        "#{@attributes[:age]} years old"
      end
    end

    Test::Foo
      .attribute(:age, "strict.integer")

    struct = Test::Foo.new(age: 18)
    expect(struct.age).to eql("18 years old")
  end

  context "keeping transformations" do
    it "works for simple structs" do
      class Test::Foo < Dry::Struct
        transform_types(&:optional)
        transform_keys(&:to_sym)

        attribute :address do
          attribute :city, "string"
        end
      end

      struct = Test::Foo.new("address" => {"city" => "London"})

      expect(struct.to_h).to eql(address: {city: "London"})

      struct = Test::Foo.new("address" => {"city" => nil})

      expect(struct.to_h).to eql(address: {city: nil})
    end

    it "works for arrays" do
      class Test::Foo < Dry::Struct
        transform_types(&:optional)
        transform_keys(&:to_sym)

        attribute :address, "array" do
          attribute :city, "string"
        end
      end

      struct = Test::Foo.new("address" => ["city" => "London"])

      expect(struct.to_h).to eql(address: [city: "London"])

      struct = Test::Foo.new("address" => ["city" => nil])

      expect(struct.to_h).to eql(address: [city: nil])
    end

    example "explicit structs cancel transformations" do
      class Test::Foo < Dry::Struct
        transform_types(&:optional)
        transform_keys(&:to_sym)

        attribute :address, Dry::Struct do
          attribute :city, "string"
        end
      end

      expect(Test::Foo.valid?("address" => {"city" => "London"})).to be(false)
      expect(Test::Foo.valid?("address" => {city: nil})).to be(false)
      expect(Test::Foo.valid?("address" => {city: "London"})).to be(true)
    end

    example "non-polymorphic array types cancel transformations" do
      class Test::Foo < Dry::Struct
        transform_types(&:optional)
        transform_keys(&:to_sym)

        attribute :address, Dry::Types["array"].of(Dry::Struct) do
          attribute :city, "string"
        end
      end

      expect(Test::Foo.valid?("address" => ["city" => "London"])).to be(false)
      expect(Test::Foo.valid?("address" => [city: nil])).to be(false)
      expect(Test::Foo.valid?("address" => [city: "London"])).to be(true)
    end
  end

  context "when given a class as nested type with a mapped attribute" do
    module DryTypes
      include Dry.Types()
    end

    class NestedStruct < Dry::Struct
      attribute :something, DryTypes::String
    end

    class TestStruct < Dry::Struct
      attribute :hash, DryTypes::Hash.map(DryTypes::Coercible::Symbol, NestedStruct)
    end

    it "throws a dry error if a nested attribute is missing" do
      expect do
        TestStruct.new({hash: {first: {}}})
      end.to raise_exception(Dry::Struct::Error)
    end
  end
end
