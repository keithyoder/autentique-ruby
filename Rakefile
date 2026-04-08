# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'json'

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

namespace :schema do
  desc 'Update GraphQL schema fixture from Autentique API'
  task :dump do
    require 'autentique'

    api_key = ENV['AUTENTIQUE_API_KEY']
    abort 'AUTENTIQUE_API_KEY environment variable is required' if api_key.nil? || api_key.empty?

    puts 'Fetching schema from Autentique API...'

    http = GraphQL::Client::HTTP.new('https://api.autentique.com.br/v2/graphql') do
      define_method(:headers) { |_| { 'Authorization' => "Bearer #{api_key}" } }
    end

    schema_path = File.expand_path('spec/fixtures/graphql_schema.json', __dir__)
    GraphQL::Client.dump_schema(http, schema_path)

    puts "Schema written to #{schema_path}"
  end
end