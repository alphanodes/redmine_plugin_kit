# frozen_string_literal: true

class User < Rails.version < '7.1' ? ActiveRecord::Base : ApplicationRecord
  has_many :issues

  def self.current
    User.first
  end

  def anonymous?
    false
  end
end
