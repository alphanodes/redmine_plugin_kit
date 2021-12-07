# frozen_string_literal: true

require_relative 'app/helpers/redmine_test_plugin_settings_helper'

require_relative 'lib/redmine_test_plugin/hooks/model_hook'
require_relative 'lib/redmine_test_plugin/hooks/view_hook'

require_relative 'lib/redmine_test_plugin/patches/issue_patch'
require_relative 'lib/redmine_test_plugin/patches/user_patch'

module RedmineTestPlugin
end
