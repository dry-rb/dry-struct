# frozen_string_literal: true

require 'dry/struct/compiler'

RSpec.describe Dry::Struct::Compiler do
  subject(:compiler) { described_class.new(Dry::Types) }

  let(:address) do
    Dry.Struct(street: 'string', city?: 'optional.string')
  end

  it 'compiles struct back to the same class' do
    expect(compiler.(address.to_ast)).to be(address)
  end

  it 'raises an error when the original struct was reclaimed' do
    ast = Dry.Struct(street: 'string', city?: 'optional.string').to_ast
    GC.start
    expect { compiler.(ast) }.to raise_error(Dry::Struct::RecycledStructError)
  end

  context 'struct constructor' do
    let(:address) { super().constructor(:itself.to_proc) }

    specify do
      expect(compiler.(address.to_ast)).to eql(address)
    end
  end

  context 'optional struct' do
    let(:address) { super().optional }

    specify do
      expect(compiler.(address.to_ast)).to eql(address)
    end
  end
end
