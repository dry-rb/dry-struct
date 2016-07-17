RSpec.describe Dry::Struct::VERSION do
  let(:gemspec_path) { DryStructSpec::ROOT.join('dry-struct.gemspec').to_s }

  it 'matches specification version' do
    specification = Gem::Specification.load(gemspec_path)

    expect(Dry::Struct::VERSION).to eql(specification.version.to_s)
  end
end
