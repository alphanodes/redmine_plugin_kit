# frozen_string_literal: true

module RedmineTestPlugin
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        true
      end
    end
  end
end
