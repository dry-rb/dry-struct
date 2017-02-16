RSpec.describe Dry::Struct do
  let(:user_type) { Test::User }
  let(:root_type) { Test::SuperUser }

  before do
    module Test
      class Address < Dry::Struct
        attribute :city, 'strict.string'
        attribute :zipcode, 'coercible.string'
      end

      # This abstract user guarantees User preserves schema definition
      class AbstractUser < Dry::Struct
        attribute :name, 'coercible.string'
        attribute :age, 'coercible.int'
        attribute :address, Test::Address
      end

      class User < AbstractUser
      end

      class SuperUser < User
        attributes(root: 'strict.bool')
      end
    end
  end

  it_behaves_like Dry::Struct do
    subject(:type) { root_type }
  end

  describe '.new' do
    it 'raises StructError when attribute constructor failed' do
      expect {
        user_type[age: {}]
      }.to raise_error(
        Dry::Struct::Error,
        '[Test::User.new] :name is missing in Hash input'
      )

      expect {
        user_type[name: :Jane, age: '21', address: nil]
      }.to raise_error(
        Dry::Struct::Error,
        '[Test::Address.new] :city is missing in Hash input'
      )
    end

    it 'passes through values when they are structs already' do
      address = Test::Address.new(city: 'NYC', zipcode: '312')
      user = user_type[name: 'Jane', age: 21, address: address]

      expect(user.address).to be(address)
    end

    it 'creates an empty struct when called without arguments' do
      class Test::Empty < Dry::Struct
        @constructor = Dry::Types['strict.hash'].strict(schema)
      end

      expect { Test::Empty.new }.to_not raise_error
    end
  end

  describe '.attribute' do
    def assert_valid_struct(user)
      expect(user.name).to eql('Jane')
      expect(user.age).to be(21)
      expect(user.address.city).to eql('NYC')
      expect(user.address.zipcode).to eql('123')
    end

    it 'defines attributes for the constructor' do
      user = user_type[
        name: :Jane, age: '21', address: { city: 'NYC', zipcode: 123 }
      ]

      assert_valid_struct(user)
    end

    it 'ignores unknown keys' do
      user = user_type[
        name: :Jane, age: '21', address: { city: 'NYC', zipcode: 123 }, invalid: 'foo'
      ]

      assert_valid_struct(user)
    end

    it 'merges attributes from the parent struct' do
      user = root_type[
        name: :Jane, age: '21', root: true, address: { city: 'NYC', zipcode: 123 }
      ]

      assert_valid_struct(user)

      expect(user.root).to be(true)
    end

    it 'raises error when type is missing' do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar
        end
      }.to raise_error(ArgumentError)
    end

    it 'raises error when attribute is defined twice' do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar, 'strict.string'
          attribute :bar, 'strict.string'
        end
      }.to raise_error(
        Dry::Struct::RepeatedAttributeError,
        'Attribute :bar has already been defined'
      )
    end

    it 'allows to redefine attributes in a subclass' do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar, 'strict.string'
        end

        class Test::Bar < Test::Foo
          attribute :bar, 'strict.int'
        end
      }.not_to raise_error
    end

    it 'can be chained' do
      class Test::Foo < Dry::Struct
      end

      Test::Foo
        .attribute(:foo, 'strict.string')
        .attribute(:bar, 'strict.int')

      foo = Test::Foo.new(foo: 'foo', bar: 123)

      expect(foo.foo).to eql('foo')
      expect(foo.bar).to eql(123)
    end
  end

  describe '.inherited' do
    it 'does not register Value' do
      expect { Dry::Struct.inherited(Dry::Struct::Value) }
        .to_not change(Dry::Types, :type_keys)
    end
  end

  describe 'when inheriting a struct from another struct' do
    it 'also inherits the constructor_type' do
      class Test::Parent < Dry::Struct; constructor_type(:schema); end
      class Test::Child < Test::Parent; end
      expect(Test::Child.constructor_type).to eql(:schema)
    end
  end

  describe 'with a blank schema' do
    it 'works for blank structs' do
      class Test::Foo < Dry::Struct; end
      expect(Test::Foo.new.to_h).to eql({})
    end
  end

  describe 'with a non-strict schema' do
    subject(:struct) do
      Class.new(Dry::Struct) do
        constructor_type(:schema)

        attribute :name, Dry::Types['strict.string'].default('Jane')
        attribute :age, Dry::Types['strict.int']
        attribute :admin, Dry::Types['strict.bool'].default(true)
      end
    end

    it 'sets missing values using default-value types' do
      attrs = { name: 'Jane', age: 21, admin: true }

      expect(struct.new(name: 'Jane', age: 21).to_h).to eql(attrs)
      expect(struct.new(age: 21).to_h).to eql(attrs)
    end

    it 'raises error when values have incorrect types' do
      expect { struct.new(name: 'Jane', age: 21, admin: 'true') }.to raise_error(
        Dry::Struct::Error, %r["true" \(String\) has invalid type for :admin]
      )

      expect { struct.new }.to raise_error(
        Dry::Types::ConstraintError, /nil violates constraints/
      )
    end
  end

  describe '#to_hash' do
    let(:parent_type) { Test::Parent }

    before do
      module Test
        class Parent < User
          attribute :children, Dry::Types['coercible.array'].member(Test::User)
        end
      end
    end

    it 'returns hash with attributes' do
      attributes  = {
        name: 'Jane',
        age:  29,
        address: { city: 'NYC', zipcode: '123' },
        children: [
          { name: 'Joe', age: 3, address: { city: 'NYC', zipcode: '123' } }
        ]
      }

      expect(parent_type[attributes].to_hash).to eql(attributes)
    end
  end

  describe 'unanonymous structs' do
    let(:struct) do
      Class.new(Dry::Struct) do
        def self.name
          'PersonName'
        end

        attribute :name, 'strict.string'
      end
    end

    before do
      struct_type = struct

      Test::Person = Class.new(Dry::Struct) do
        attribute :name, struct_type
      end
    end

    it 'works fine' do
      expect(struct.new(name: 'Jane')).to be_an_instance_of(struct)
      expect(Test::Person.new(name: { name: 'Jane' })).to be_an_instance_of(Test::Person)
    end
  end
end
