# frozen_string_literal: true

ActiveRecord::Schema.define version: 0 do
  create_table 'users', force: true do |t|
    t.string 'name'
    t.string 'language'
  end

  create_table 'issues', force: true do |t|
    t.integer  'project_id'
    t.string 'subject'
    t.string 'description'
    t.boolean 'closed'
    t.integer 'user_id'
    t.integer 'author_id'
  end

  create_table 'projects', force: true do |t|
    t.string   'name'
    t.text     'description'
    t.string   'identifier'
    t.integer  'status'
  end
end
