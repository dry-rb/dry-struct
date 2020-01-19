# frozen_string_literal: true

require_relative 'support/coverage'
require_relative 'support/warnings'

require 'pathname'

Warning.ignore(/regexp_parser/)
Warning.ignore(/parser/)
Warning.ignore(/slice\.rb/)

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

Dir[Pathname(__dir__).join('shared/*.rb')].each(&method(:require))
require 'dry/types/spec/types'

RSpec.configure do |config|
  config.exclude_pattern = '**/pattern_matching_spec.rb' \
    unless RUBY_VERSION >= '2.7'

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
  config.filter_run_when_matching :focus

  config.around :each, :suppress_deprecations do |ex|
    logger = Dry::Core::Deprecations.logger
    Dry::Core::Deprecations.set_logger!(DryStructSpec::ROOT.join('log/deprecations.log'))
    ex.run
    Dry::Core::Deprecations.set_logger!(logger)
  end
end
