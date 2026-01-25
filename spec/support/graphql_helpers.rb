# frozen_string_literal: true

GraphQLErrors = Struct.new(:any?, :messages) # rubocop:disable Lint/StructNewOverride
GraphQLDocumentsData = Struct.new(:data)
GraphQLData = Struct.new(
  :document,
  :documents,
  :delete_document,
  :folders,
  :create_folder,
  :delete_folder
)
GraphQLResponse = Struct.new(:errors, :data)

module GraphQLHelpers
  # Accept all optional values as a single hash
  def graphql_success(values = {})
    GraphQLResponse.new(
      GraphQLErrors.new(false, []),
      GraphQLData.new(
        values[:document],
        values[:documents],
        values[:delete_document],
        values[:folders],
        values[:create_folder],
        values[:delete_folder]
      )
    )
  end

  def graphql_error(messages)
    GraphQLResponse.new(
      GraphQLErrors.new(true, Array(messages)),
      nil
    )
  end
end
