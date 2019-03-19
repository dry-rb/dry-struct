# frozen_string_literal: true

RSpec.shared_examples_for Dry::Struct do
  let(:jane) { { name: :Jane, age: '21', root: true, address: { city: 'NYC', zipcode: 123 } } }
  let(:mike) { { name: :Mike, age: '43', root: false, address: { city: 'Atlantis', zipcode: 456 } } }
  let(:john) { { name: :John, age: '36', root: false, address: { city: 'San Francisco', zipcode: 789 } } }

  describe '#eql' do
    context 'when struct values are equal' do
      let(:user_1) { type[jane] }
      let(:user_2) { type[jane] }

      it 'returns true' do
        expect(user_1).to eql(user_2)
      end
    end

    context 'when struct values are not equal' do
      let(:user_1) { type[jane] }
      let(:user_2) { type[mike] }

      it 'returns false' do
        expect(user_1).to_not eql(user_2)
      end
    end
  end

  describe '#hash' do
    context 'when struct values are equal' do
      let(:user_1) { type[jane] }
      let(:user_2) { type[jane] }

      it 'the hashes are equal' do
        expect(user_1.hash).to eql(user_2.hash)
      end
    end

    context 'when struct values are not equal' do
      let(:user_1) { type[jane] }
      let(:user_2) { type[mike] }

      it 'the hashes are not equal' do
        expect(user_1.hash).to_not eql(user_2.hash)
      end
    end
  end

  describe '#new' do
    let(:original) { type[jane].freeze }
    let(:updated) { original.new(age: '25') }

    it 'applies changeset' do
      expect(updated.age).to eq 25
    end

    it 'remains other attributes the same' do
      expect(updated.name).to eq original.name
      expect(updated.root).to eq original.root
      expect(updated.address).to eq original.address
    end

    it 'does not do deep merge' do
      expect { original.new(address: { city: 'LA' }) }
        .to raise_error(Dry::Struct::Error)
    end

    it 'has the __new__ alias' do
      expect(updated).to eql(original.__new__(age: '25'))
    end

    it 'uses attribute values, not accessors result' do
      decorator = Module.new do
        def name
          :"#{ super } Doe"
        end
      end

      original.class.prepend(decorator)
      expect(updated.name).to eql(:'Jane Doe')
    end

    context 'default values' do
      subject(:struct) do
        Class.new(Dry::Struct) {
          attribute :name, 'strict.string'
          attribute :age,  Dry::Types['strict.integer'].default(18)
        }.new(name: 'Jack', age: 20)
      end

      it "doesn't re-write values with defaults if keys are missing in the changeset" do
        expect(struct.new(name: 'John').age).to eql(20)
      end
    end
  end

  describe '#inspect' do
    let(:user_1) { type[jane] }

    it 'lists attributes' do
      expect(user_1.inspect).to eql(
        %Q(#<#{type} name="Jane" age=21 address=#<Test::Address city="NYC" zipcode="123"> root=true>)
      )
    end
  end

  context 'class interface' do
    it_behaves_like Dry::Types::Nominal

    describe '.|' do
      let(:sum_type) { type | Dry::Types['strict.nil'] }

      it 'returns Sum type' do
        expect(sum_type).to be_constrained
        expect(sum_type[nil]).to be_nil
        expect(sum_type[jane]).to eql(type[jane])
      end
    end

    describe '.constructor' do
      it 'uses constructor function to process input' do
        expect(type.constructor(&:to_h)[jane.to_a]).to be_eql type[jane]
      end
    end

    describe '.default?' do
      it 'is not a default' do
        expect(type).not_to be_default
      end
    end

    describe '.default' do
      let(:default_type) { type.default(type[jane].freeze) }

      it 'returns Default type' do
        expect(default_type).to be_instance_of(Dry::Types::Default)
        expect(default_type[]).to eql(type[jane])
      end
    end

    describe '.enum' do
      let(:enum_type) { type.enum(type[jane], type[mike]) }

      it 'returns Enum type' do
        expect(enum_type[type[jane]]).to eql(type[jane])
        expect { enum_type[type[john]] }.to raise_error(Dry::Types::ConstraintError)
      end
    end

    describe '.optional' do
      let(:optional_type) { type.optional }

      it 'returns Sum type' do
        expect(optional_type).to eql(Dry::Types['strict.nil'] | type)
        expect(optional_type[nil]).to be_nil
        expect(optional_type[jane]).to eql(type[jane])
      end

      it 'rejects invalid input' do
        expect { optional_type[foo: :bar] }.to raise_error(Dry::Types::ConstraintError)
      end
    end

    describe '.has_attribute?' do
      it 'checks if a struct has an attribute' do
        expect(type.has_attribute?(:name)).to be true
        expect(type.has_attribute?(:last_name)).to be false
      end
    end

    describe '.attribute?', :suppress_deprecations do
      it 'checks if a struct has an attribute' do
        expect(type.attribute?(:name)).to be true
        expect(type.attribute?(:last_name)).to be false
      end
    end

    describe '.attribute_names' do
      it 'returns the list of schema keys' do
        expect(type.attribute_names).to eql(%i(name age address root))
      end

      it 'invalidates the cache on adding a new attribute' do
        expect(type.attribute_names).to eql(%i(name age address root))
        type.attribute(:something_else, Dry::Types['any'])
        expect(type.attribute_names).to eql(%i(name age address root something_else))
      end
    end

    describe '.meta' do
      it 'builds a new class with meta' do
        struct_with_meta = type.meta(foo: :bar)

        expect(struct_with_meta.meta).to eql(foo: :bar)
      end

      it 'return an empty hash' do
        expect(type.meta).to eql({})
      end
    end

    describe '.transform_types' do
      it 'adds a type transformation' do
        type.transform_types { |t| t.meta(tranformed: true) }
        type.attribute(:city, Dry::Types["strict.string"])
        expect(type.schema.key(:city).type.meta).to eql(tranformed: true)
      end

      it 'accepts a proc' do
        type.transform_types(-> (key) { key.meta(tranformed: true) })
        type.attribute(:city, Dry::Types["strict.string"])
        expect(type.schema.key(:city).type.meta).to eql(tranformed: true)
      end
    end

    describe '.transform_keys' do
      let(:jane_str) do
        {
          'name' => :Jane,
          'age' => '21',
          'root' => true,
          'address' => { city: 'NYC', zipcode: 123 }
        }
      end

      it 'adds a key tranformation' do
        type.transform_keys(&:to_sym)
        expect(type.(jane_str)).to eql(type.(jane))
      end

      it 'accepts a proc' do
        type.transform_keys(:to_sym.to_proc)
        expect(type.(jane_str)).to eql(type.(jane))
      end
    end

    describe '.inherited' do
      it "doesn't track Struct/Value descendats" do
        expect(Dry::Struct).not_to be_a(Dry::Core::DescendantsTracker)
        expect(Dry::Struct::Value).not_to be_a(Dry::Core::DescendantsTracker)
      end
    end
  end

  it 'registered without wrapping' do
    expect(Dry::Types[type]).to be type
  end
end
