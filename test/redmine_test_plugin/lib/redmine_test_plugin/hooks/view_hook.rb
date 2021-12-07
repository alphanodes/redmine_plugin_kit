# frozen_string_literal: true

module RedmineTestPlugin
  module Hooks
    class ViewHook < Redmine::Hook::ViewListener
      def view_layouts_base_content(_context = {})
        true
      end
    end
  end
end
