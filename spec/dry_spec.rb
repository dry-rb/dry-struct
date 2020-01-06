# frozen_string_literal: true

RSpec.describe Dry do
  describe '.Struct' do
    it 'returns a struct' do
      struct_klass = Dry.Struct(name: 'strict.string')

      struct = struct_klass.new(name: 'Test')
      expect(struct.attributes).to eql(name: 'Test')
    end

    context 'initializer block' do
      before do
        module Test
          Library = Dry.Struct do
            schema schema.strict

            attribute :library, 'string'
            attribute :language, 'string'

            def qualified
              "#{language}/#{library}"
            end
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

      it 'can define methods within block' do
        attributes = { library: 'dry-struct', language: 'Ruby' }
        expect(Test::Library.new(attributes).qualified).to eql('Ruby/dry-struct')
      end
    end
  end
end
