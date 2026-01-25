# Contributing to Autentique Ruby Gem

First off, thank you for considering contributing to the Autentique Ruby gem! It's people like you that make this gem better for everyone.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- Be respectful and inclusive
- Be collaborative
- Be professional
- Focus on what is best for the community

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**

```markdown
**Description**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Initialize client with '...'
2. Call method '...'
3. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment:**
- Ruby version:
- Gem version:
- OS:

**Additional context**
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- A clear and descriptive title
- A detailed description of the proposed functionality
- Examples of how the feature would be used
- Why this feature would be useful

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Write clear, descriptive commit messages**
3. **Add tests** for your changes
4. **Ensure tests pass**: `bundle exec rspec`
5. **Check code style**: `bundle exec rubocop`
6. **Update documentation** if needed
7. **Submit your pull request**

## Development Process

### Setting Up Your Development Environment

```bash
# Clone your fork
git clone https://github.com/your-username/autentique-ruby.git
cd autentique-ruby

# Install dependencies
bundle install

# Set up your API key for testing
export AUTENTIQUE_API_KEY="your_sandbox_key"

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/autentique_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Style

This project follows the [Ruby Style Guide](https://rubystyle.guide/). We use RuboCop to enforce style:

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Writing Tests

- Write tests for all new functionality
- Maintain or improve code coverage
- Use RSpec for testing
- Use VCR cassettes for API interactions
- Mock external dependencies when appropriate

Example test structure:

```ruby
RSpec.describe Autentique::Resources::Documents do
  let(:client) { test_client }
  let(:documents) { described_class.new(client) }

  describe '#create' do
    it 'creates a document successfully' do
      VCR.use_cassette('documents/create') do
        result = documents.create(
          file: 'spec/fixtures/test.pdf',
          document: { name: 'Test' },
          signers: [{ email: 'test@example.com', action: 'SIGN' }]
        )

        expect(result).to be_a(Autentique::Models::Document)
        expect(result.name).to eq('Test')
      end
    end
  end
end
```

### Commit Messages

Write clear, descriptive commit messages:

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests when relevant

Good commit messages:
```
Add support for document templates

Implement folder management API
- Add Folders resource class
- Add list, create, delete methods
- Add comprehensive tests

Fixes #42
```

### Documentation

- Update README.md for new features
- Add YARD documentation to public methods
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/)
- Add examples for complex features

Example documentation:

```ruby
# Retrieve a document by ID
#
# @param id [String] The document UUID
# @return [Models::Document] The retrieved document
# @raise [NotFoundError] if document doesn't exist
# @raise [AuthenticationError] if API key is invalid
#
# @example
#   client = Autentique::Client.new(api_key: 'key')
#   doc = client.documents.find('document-uuid')
#   puts doc.name
def find(id)
  # implementation
end
```

## Project Structure

```
autentique-ruby/
├── lib/
│   ├── autentique/
│   │   ├── models/
│   │   │   └── document.rb
│   │   ├── resources/
│   │   │   ├── documents.rb
│   │   │   └── folders.rb
│   │   ├── client.rb
│   │   ├── errors.rb
│   │   └── version.rb
│   └── autentique.rb
├── spec/
│   ├── fixtures/
│   ├── models/
│   ├── resources/
│   ├── autentique_spec.rb
│   └── spec_helper.rb
├── examples/
├── README.md
├── CHANGELOG.md
└── autentique.gemspec
```

## Adding New Features

When adding a new feature:

1. **Create an issue** discussing the feature
2. **Get feedback** from maintainers
3. **Implement** the feature with tests
4. **Document** the feature
5. **Update** CHANGELOG.md
6. **Submit** a pull request

## Release Process

Maintainers will handle releases:

1. Update version in `lib/autentique/version.rb`
2. Update CHANGELOG.md
3. Commit changes
4. Create git tag
5. Push to GitHub
6. Build and publish gem

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion on GitHub
- Contact maintainers directly

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make this project better. We appreciate your time and effort! 🎉
