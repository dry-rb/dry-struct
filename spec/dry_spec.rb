
RSpec.describe Dry do
  describe '.Struct' do
    context 'constructor types' do
      %i[permissive schema strict strict_with_defaults].each do |constructor|
        it "returns a struct with constructor type #{constructor}" do
          struct_klass = Dry.Struct(name: 'strict.string')

          struct = struct_klass.new(name: 'Test')
          expect(struct.__attributes__).to eq(name: 'Test')
        end
      end
    end

    context 'initializer block' do
      before do
        module Test
          Library = Dry.Struct do
            input input.strict

            attribute :library, 'strict.string'
            attribute :language, 'strict.string'
          end
        end
      end

      it 'sets the correct constructor type' do
        expect {
          Test::Library.new(library: 'dry-rb')
        }.to raise_error(
          Dry::Struct::Error,
          '[Test::Library.new] :language is missing in Hash input'
        )
      end

      it 'sets the correct attributes' do
        attributes = { library: 'dry-struct', language: 'Ruby' }
        expect(Test::Library.new(attributes).to_h).to eql(attributes)
      end
    end
  end
end
