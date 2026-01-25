# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc 'Run tests'
task default: %i[spec rubocop]

desc 'Start an interactive console'
task :console do
  require 'irb'
  require 'autentique'
  ARGV.clear
  IRB.start
end
