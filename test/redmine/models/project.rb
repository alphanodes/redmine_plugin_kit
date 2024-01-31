# frozen_string_literal: true

class Project < ActiveRecord::Base
  STATUS_ACTIVE = 1
  has_many :issues, dependent: :destroy

  def active?
    status == STATUS_ACTIVE
  end
end
