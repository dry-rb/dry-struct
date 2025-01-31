# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/struct/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-struct"
  spec.authors       = ["Piotr Solnica"]
  spec.email         = ["piotr.solnica@gmail.com"]
  spec.license       = "MIT"
  spec.version       = Dry::Struct::VERSION.dup

  spec.summary       = "Typed structs and value objects"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-struct"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-struct.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["changelog_uri"]         = "https://github.com/dry-rb/dry-struct/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]       = "https://github.com/dry-rb/dry-struct"
  spec.metadata["bug_tracker_uri"]       = "https://github.com/dry-rb/dry-struct/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1.0"

  # to update dependencies edit project.yml
  spec.add_dependency "dry-core", "~> 1.1"
  spec.add_dependency "dry-types", "~> 1.8", ">= 1.8.2"
  spec.add_dependency "ice_nine", "~> 0.11"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
