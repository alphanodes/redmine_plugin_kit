# frozen_string_literal: true

ActiveRecord::Schema.define version: 0 do
  create_table 'users', force: true do |t|
    t.column 'name', :string
    t.column 'language', :string
  end

  create_table 'issues', force: true do |t|
    t.integer  'project_id'
    t.column 'subject', :string
    t.column 'description', :string
    t.column 'closed', :boolean
    t.column 'user_id', :integer
    t.column 'author_id', :integer
  end

  create_table 'projects', force: true do |t|
    t.string   'name'
    t.text     'description'
    t.string   'identifier'
    t.integer  'status'
  end
end
