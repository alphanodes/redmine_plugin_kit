# frozen_string_literal: true

class Project < Rails.version < '7.1' ? ActiveRecord::Base : ApplicationRecord
  STATUS_ACTIVE = 1
  has_many :issues, dependent: :destroy

  def active?
    status == STATUS_ACTIVE
  end
end
