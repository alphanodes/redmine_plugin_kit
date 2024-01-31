# frozen_string_literal: true

require_relative 'project'
require_relative 'user'

class Issue < Rails.version < '7.1' ? ActiveRecord::Base : ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :author, class_name: 'User'
end
