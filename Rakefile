require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new(:doc)
