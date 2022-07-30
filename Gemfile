# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-logic", github: "dry-rb/dry-logic", branch: "main"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"

group :test do
  gem "dry-monads", github: "dry-rb/dry-monads", branch: "main"
end

group :tools do
  gem "pry"
  gem "pry-byebug", platform: :mri
end

group :benchmarks do
  gem "activerecord"
  gem "attrio"
  gem "benchmark-ips"
  gem "fast_attributes"
  gem "hotch", platform: :mri
  gem "sqlite3", platform: :mri
  gem "virtus"
end
