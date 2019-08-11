source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
  gem 'codeclimate-test-reporter', platform: :mri, require: false
  gem 'dry-monads'
  gem 'simplecov', require: false
  gem 'warning'
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
