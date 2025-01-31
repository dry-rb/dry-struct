# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-types", path: "~/dev/dry-rb/dry-types"

group :test do
  gem "dry-monads", github: "dry-rb/dry-monads", branch: "main"
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
