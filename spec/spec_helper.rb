if RUBY_ENGINE == 'ruby' && ENV['COVERAGE'] == 'true'
  require 'yaml'
  rubies = YAML.load(File.read(File.join(__dir__, '..', '.travis.yml')))['rvm']
  latest_mri = rubies.select { |v| v =~ /\A\d+\.\d+.\d+\z/ }.max

  if RUBY_VERSION == latest_mri
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end
  end
end

require 'pathname'

begin
  require 'warning'
  Warning.ignore(/regexp_parser/)
  Warning.ignore(/mutant/)
  Warning.ignore(/parser/)
  Warning.ignore(/slice\.rb/)
rescue LoadError
end

module DryStructSpec
  ROOT = Pathname.new(__dir__).parent.expand_path.freeze
end

$LOAD_PATH.unshift DryStructSpec::ROOT.join('lib').to_s
$VERBOSE = true

require 'dry-struct'

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

begin
  require 'mutant'

  module Mutant
    class Selector
      class Expression < self
        undef call
        def call(_subject)
          integration.all_tests
        end
      end # Expression
    end # Selector
  end # Mutant
rescue LoadError; end

Dir[Pathname(__dir__).join('shared/*.rb')].each(&method(:require))
require 'dry/types/spec/types'

RSpec.configure do |config|
  config.before do
    @types = Dry::Types.container._container.keys

    module Test
      def self.remove_constants
        constants.each { |const| remove_const(const) }
        self
      end
    end
  end

  config.after do
    container = Dry::Types.container._container
    (container.keys - @types).each { |key| container.delete(key) }
    Dry::Types.instance_variable_set('@type_map', Concurrent::Map.new)

    Object.send(:remove_const, Test.remove_constants.name)
  end

  config.order = :random
end
