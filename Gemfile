# frozen_string_literal: true

source 'https://rubygems.org'

eval_gemfile 'Gemfile.devtools'

gemspec

gem 'dry-types', github: 'dry-rb/dry-types'

group :test do
  gem 'dry-monads'
end

group :tools do
  gem 'pry'
  gem 'pry-byebug', platform: :mri
end

group :benchmarks do
  gem 'sqlite3'
  gem 'activerecord'
  gem 'benchmark-ips'
  gem 'virtus'
  gem 'fast_attributes'
  gem 'attrio'
  gem 'hotch'
end
