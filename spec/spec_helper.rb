# frozen_string_literal: true

# Suppress warnings from gem dependencies
$VERBOSE = nil

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_group 'Resources', 'lib/autentique/resources'
    add_group 'Models',    'lib/autentique/models'
    add_group 'Client',    'lib/autentique/client'
  end
end

require 'autentique'
require 'webmock/rspec'
require 'vcr'
require_relative 'support/graphql_helpers'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Reset configuration and stub GraphQL schema before each test
  config.before do
    Autentique.reset
    stub_graphql_schema
  end
end

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  # Ignore introspection queries to let our stub handle them
  config.ignore_request do |request|
    request.body =~ /IntrospectionQuery/
  end
end

# Stub GraphQL schema introspection for tests
def stub_graphql_schema
  schema_fixture = File.read(File.expand_path('fixtures/graphql_schema.json', __dir__))
  schema = GraphQL::Client.load_schema(JSON.parse(schema_fixture))

  stub_request(:post, 'https://api.autentique.com.br/v2/graphql')
    .with { |request| request.body =~ /IntrospectionQuery/ }
    .to_return(
      status: 200,
      body: schema_fixture,
      headers: { 'Content-Type' => 'application/json' }
    )

  allow(GraphQL::Client).to receive(:load_schema).and_return(schema)
end

# Helper method to create a test client
def test_client(api_key: 'test_api_key', sandbox: true)
  Autentique::Client.new(api_key: api_key, sandbox: sandbox)
end
