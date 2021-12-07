# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :issues

  def self.current
    User.first
  end

  def anonymous?
    false
  end
end
