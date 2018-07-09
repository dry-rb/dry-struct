RSpec.describe Dry::Struct do
  include_context 'user type'

  it_behaves_like Dry::Struct do
    subject(:type) { root_type }
  end

  shared_examples_for 'typical constructor' do
    it 'raises StructError when attribute constructor failed' do
      expect {
        construct_user(name: :Jane, age: '21', address: nil)
      }.to raise_error(
        Dry::Struct::Error,
        /\[Test::User.new\] nil \(NilClass\) has invalid type for :address/
      )
    end

    it 'passes through values when they are structs already' do
      address = Test::Address.new(city: 'NYC', zipcode: '312')
      user = construct_user(name: 'Jane', age: 21, address: address)

      expect(user.address).to be(address)
    end

    it 'returns itself when an argument is an instance of given class' do
      user = user_type[
        name: :Jane, age: '21', address: { city: 'NYC', zipcode: 123 }
      ]

      expect(construct_user(user)).to be_equal(user)
    end

    it 'creates an empty struct when called without arguments' do
      class Test::Empty < Dry::Struct
        @constructor = Dry::Types['strict.hash'].strict(schema)
      end

      expect { Test::Empty.new }.to_not raise_error
    end
  end

  describe '.new' do
    def construct_user(attributes)
      user_type.new(attributes)
    end

    it_behaves_like 'typical constructor'

    it 'returns new object when an argument is an instance of subclass' do
      user = root_type[
        name: :Jane, age: '21', root: true, address: { city: 'NYC', zipcode: 123 }
      ]

      expect(construct_user(user)).to be_instance_of(user_type)
    end

    context 'with default' do
      it 'resolves missing values with defaults' do
        struct = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['strict.string'].default('Jane')
          attribute :admin, Dry::Types['strict.bool'].default(true)
        end

        expect(struct.new.to_h).
          to eql(name: 'Jane', admin: true)
      end

      it "doesn't tolerate missing required keys" do
        struct = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['strict.string'].default('Jane')
          attribute :age, Dry::Types['strict.integer']
        end

        expect { struct.new }.to raise_error(Dry::Struct::Error, /:age is missing in Hash input/)
      end

      it "resolves missing values for nested attributes" do
        struct = Class.new(Dry::Struct) do
          attribute :kid do
            attribute :age, Dry::Types['strict.integer'].default(16)
          end
        end

        expect(struct.new.to_h).
          to eql({kid: {age: 16}})
      end

      it "doesn't tolerate missing required keys for nested attributes" do
        struct = Class.new(Dry::Struct) do
          attribute :kid do
            attribute :name, Dry::Types['strict.string'].default('Jane')
            attribute :age, Dry::Types['strict.integer']
          end
        end

        expect { struct.new }.to raise_error(Dry::Struct::Error, /:age is missing in Hash input/)
      end
    end

    it "doesn't coerce to a hash recurcively" do
      properties = Class.new(Dry::Struct) do
        attribute :age, Dry::Types['strict.integer'].constructor(-> v { v + 1 })
      end

      struct = Class.new(Dry::Struct) do
        attribute :name, Dry::Types['strict.string']
        attribute :properties, properties
      end

      original = struct.new(name: 'Jane', properties: { age: 20 })

      expect(original.properties.age).to eql(21)

      transformed = original.new(name: 'John')

      expect(transformed.properties.age).to eql(21)
    end
  end

  describe '.call' do
    def construct_user(attributes)
      user_type.call(attributes)
    end

    it_behaves_like 'typical constructor'

    it 'returns itself when an argument is an instance of subclass' do
      user = root_type[
        name: :Jane, age: '21', root: true, address: { city: 'NYC', zipcode: 123 }
      ]

      expect(construct_user(user)).to be_equal(user)
    end
  end

  it 'defines .[] alias' do
    expect(described_class.method(:[])).to eq described_class.method(:call)
  end

  describe '.inherited' do
    it 'does not register Value' do
      expect { Dry::Struct.inherited(Dry::Struct::Value) }
        .to_not change(Dry::Types, :type_keys)
    end

    it 'adds attributes to all descendants' do
      Test::User.attribute(:signed_on, Dry::Types['strict.time'])

      expect(Test::SuperUser.schema).
        to include(signed_on: Dry::Types['strict.time'])
    end

    it "doesn't override already defined attributes accidentally" do
      admin = Dry::Types['strict.string'].enum('admin')

      Test::SuperUser.attribute(:role, admin)
      Test::User.attribute(:role, Dry::Types['strict.string'].enum('author', 'subscriber'))

      expect(Test::SuperUser.schema[:role]).to be(admin)
    end
  end

  describe 'when inheriting a struct from another struct' do
    it 'also inherits the schema' do
      class Test::Parent < Dry::Struct; input input.strict; end
      class Test::Child < Test::Parent; end
      expect(Test::Child.input).to be_strict
    end
  end

  describe 'when there is a constant with same name as new attribute type' do
    it 'ignore constant outside struct' do
      Object.send(:remove_const, :Article) if Object.const_defined?(:Article)
      Object.send(:remove_const, :ArticleForm) if Object.const_defined?(:ArticleForm)

      class Article; attr_accessor :title; end
      class ArticleForm < Dry::Struct
        module Types
          include ::Dry::Types.module
        end

        attribute :article do
          attribute :title, Types::Coercible::String.meta(omittable: true)
        end
      end

      expect(Article == ArticleForm::Article).to be_falsey
    end

    it 'prevents existing constant inside struct to be overridden' do
      Object.send(:remove_const, :Article) if Object.const_defined?(:Article)
      Object.send(:remove_const, :ArticleForm) if Object.const_defined?(:ArticleForm)

      class ArticleForm < Dry::Struct
        module Types
          include ::Dry::Types.module
        end

        class Article; attr_accessor :title; end
      end

      expect {
        ArticleForm.class_eval do
          attribute :article do
            attribute :title, Types::Coercible::String.meta(omittable: true)
          end
        end
        construct_user(name: :Jane, age: '21', address: nil)
      }.to raise_error(
        Dry::Struct::Error,
        %r|Can't create nested attribute - `ArticleForm::Article` already defined|
      )
    end
  end

  describe 'with a blank schema' do
    it 'works for blank structs' do
      class Test::Foo < Dry::Struct; end
      expect(Test::Foo.new.to_h).to eql({})
    end
  end

  describe 'default values' do
    subject(:struct) do
      Class.new(Dry::Struct) do
        attribute :name, Dry::Types['strict.string'].default('Jane')
        attribute :age, Dry::Types['strict.integer']
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
    end
  end

  describe '#to_hash' do
    let(:parent_type) { Test::Parent }

    before do
      module Test
        class Parent < User
          attribute :children, Dry::Types['coercible.array'].of(Test::User)
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

    it "doesn't unwrap blindly anything mappable" do
      struct = Class.new(Dry::Struct) do
        attribute :mappable, Dry::Types['any']
      end

      mappable = Object.new.tap do |obj|
        def obj.map
          fail
        end
      end

      value = struct.new(mappable: mappable)

      expect(value.to_h).to eql(mappable: mappable)
    end

    context "with omittable keys" do
      it "returns hash with attributes but will not try fetching omittable keys if not set" do
        type = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['string']
          attribute :last_name, Dry::Types['string'].meta(omittable: true)
        end

        attributes = { name: 'John' }
        expect(type.new(attributes).to_hash).to eq (attributes)
      end

      it "returns hash with attributes but will fetch omittable keys if set" do
        type = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['string']
          attribute :last_name, Dry::Types['string'].meta(omittable: true)
        end

        attributes = { name: 'John', last_name: 'Doe' }
        expect(type.new(attributes).to_hash).to eq (attributes)
      end

      it "returns empty hash if all attributes are ommitable and no value is set" do
        type = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['string'].meta(omittable: true)
        end

        expect(type.new.to_hash).to eq ({})
      end
    end

    context "with default value" do
      it "returns hash with attributes" do
        type = Class.new(Dry::Struct) do
          attribute :name, Dry::Types['string'].default('John')
        end

        attributes = { name: 'John' }
        expect(type.new.to_hash).to eq (attributes)
      end
    end
  end

  describe 'pseudonamed structs' do
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

  describe '#[]' do
    before do
      module Test
        class Task < Dry::Struct
          attribute :user, 'strict.string'
          undef user
        end
      end
    end

    it 'fetches raw attributes' do
      value = Test::Task[user: 'Jane']
      expect(value[:user]).to eql('Jane')
    end

    it 'raises a missing attribute error when no attribute exists' do
      value = Test::Task[user: 'Jane']

      expect { value[:name] }.
        to raise_error(Dry::Struct::MissingAttributeError).
             with_message("Missing attribute: :name")
    end

    describe 'protected methods' do
      before do
        class Test::Task
          attribute :hash, Dry::Types['strict.string']
          attribute :attributes, Dry::Types['array'].of(Dry::Types['strict.string'])
        end
      end

      it 'allows having attributes with reserved names' do
        value = Test::Task[user: 'Jane', hash: 'abc', attributes: %w(name)]

        expect(value.hash).to be_a(Integer)
        expect(value.attributes).
          to eql(user: 'Jane', hash: 'abc', attributes: %w(name))
        expect(value[:hash]).to eql('abc')
        expect(value[:attributes]).to eql(%w(name))
      end
    end
  end
end
