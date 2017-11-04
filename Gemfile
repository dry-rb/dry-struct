source 'https://rubygems.org'

gemspec

gem 'dry-types', git: 'https://github.com/dry-rb/dry-types'

group :test do
  gem 'codeclimate-test-reporter', platform: :mri, require: false
  gem 'simplecov', require: false
end

group :tools do
  gem 'byebug', platform: :mri
  gem 'mutant'
  gem 'mutant-rspec'
end

group :benchmarks do
  gem 'sqlite3'
  gem 'activerecord'
  gem 'benchmark-ips'
  gem 'virtus'
  gem 'fast_attributes'
  gem 'attrio'
end
