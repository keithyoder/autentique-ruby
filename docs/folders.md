# Folders

Folders let you organise documents within Autentique. You can list, create, and delete folders, and assign documents to a folder at creation time.

## Listing Folders

```ruby
folders = client.folders.list

folders.each do |folder|
  puts "#{folder['name']} — #{folder['id']}"
end
```

Accepts optional pagination arguments:

```ruby
folders = client.folders.list(limit: 10, page: 2)
```

## Creating a Folder

```ruby
folder = client.folders.create(name: 'Contracts 2025')
puts folder['id']

# With a parent folder
subfolder = client.folders.create(
  name: 'Q1 Contracts',
  parent_id: 'parent-folder-uuid'
)
```

## Deleting a Folder

```ruby
client.folders.delete(id: 'folder-uuid')
```

## Assigning a Document to a Folder

Pass `folder_id` when creating a document:

```ruby
document = client.documents.create(
  file: '/path/to/contract.pdf',
  document: { name: 'Contract' },
  signers: [{ email: 'signer@example.com', action: 'SIGN' }],
  folder_id: 'folder-uuid'
)
```