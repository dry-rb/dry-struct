# frozen_string_literal: true

require_relative "support/coverage"
require_relative "support/warnings"

require "pathname"

Warning.ignore(/regexp_parser/)
Warning.ignore(/parser/)
Warning.ignore(/slice\.rb/)

module DryStructSpec
  ROOT = Pathname.new(__dir__).parent.expand_path.freeze
end

$LOAD_PATH.unshift DryStructSpec::ROOT.join("lib").to_s
$VERBOSE = true

require "dry-struct"

begin
  require "pry"
  require "pry-byebug"
rescue LoadError
end

Dir[Pathname(__dir__).join("shared/*.rb")].sort.each(&method(:require))
require "dry/types/spec/types"

RSpec.configure do |config|
  config.before { stub_const("Test", Module.new) }

  config.order = :random
  config.filter_run_when_matching :focus

  config.around :each, :suppress_deprecations do |ex|
    logger = Dry::Core::Deprecations.logger
    Dry::Core::Deprecations.set_logger!(DryStructSpec::ROOT.join("log/deprecations.log"))
    ex.run
    Dry::Core::Deprecations.set_logger!(logger)
  end
end
