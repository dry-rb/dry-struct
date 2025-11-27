# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :test do
  gem "dry-monads", github: "dry-rb/dry-monads"
  gem "super_diff"
end

group :benchmarks do
  gem "activerecord"
  gem "attrio"
  gem "benchmark-ips"
  gem "fast_attributes"
  # gem "hotch", platform: :mri
  gem "sqlite3", platform: :mri
  gem "virtus"
end

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0")
  gem "debug", group: :tools, platform: :mri
end
