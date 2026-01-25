# frozen_string_literal: true

require_relative 'lib/autentique/version'

Gem::Specification.new do |spec|
  spec.name          = 'autentique'
  spec.version       = Autentique::VERSION
  spec.authors       = ['Keith Yoder']
  spec.email         = ['keith.yoder@gmail.com']

  spec.summary       = 'Ruby client for Autentique digital signature API'
  spec.description   = 'A Ruby gem for integrating with Autentique\'s document signing service via their GraphQL API'
  spec.homepage      = 'https://github.com/keithyoder/autentique-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = 'https://docs.autentique.com.br/api'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{lib,spec}/**/*', '*.md', '*.gemspec', 'LICENSE*']
      .reject { |f| File.directory?(f) }
  end

  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'graphql-client', '~> 0.18'
  spec.add_dependency 'mime-types', '~> 3.0'
end
