# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__
require File.expand_path '../redmine_test_plugin/redmine_test_plugin', __dir__

class LoaderTest < ActiveSupport::TestCase
  def setup
    @plugin_id = 'redmine_test_plugin'
  end

  # redmine_database_ready? tests
  def test_redmine_database_ready_returns_true_with_existing_table
    assert RedminePluginKit::Loader.redmine_database_ready?('users')
  end

  def test_redmine_database_ready_returns_false_with_nonexistent_table
    assert_not RedminePluginKit::Loader.redmine_database_ready?('nonexistent_table')
  end

  def test_redmine_database_ready_returns_true_without_table_argument
    assert RedminePluginKit::Loader.redmine_database_ready?
  end

  def test_redmine_database_ready_returns_false_when_no_database_error
    original_method = ActiveRecord::Base.method :connection
    ActiveRecord::Base.define_singleton_method(:connection) { raise ActiveRecord::NoDatabaseError }

    assert_not RedminePluginKit::Loader.redmine_database_ready?('users')
  ensure
    ActiveRecord::Base.define_singleton_method :connection, original_method
  end

  def test_redmine_database_ready_returns_false_when_connection_not_established
    original_method = ActiveRecord::Base.method :connection
    ActiveRecord::Base.define_singleton_method(:connection) { raise ActiveRecord::ConnectionNotEstablished }

    assert_not RedminePluginKit::Loader.redmine_database_ready?('users')
  ensure
    ActiveRecord::Base.define_singleton_method :connection, original_method
  end

  def test_add_patch
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch 'Issue'

    assert loader.apply!
  end

  def test_add_patch_as_hash
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch({ target: Issue, patch: 'Issue' })

    assert loader.apply!
  end

  def test_add_patch_as_hash_without_patch
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch({ target: Issue })

    assert loader.apply!
  end

  def test_add_multiple_patches
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch %w[Issue User]

    assert loader.apply!
  end

  def test_add_invalid_patch
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch 'Issue2'

    assert_raises NameError do
      loader.apply!
    end
  end

  def test_add_helper
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper 'Settings'

    assert loader.apply!
  end

  def test_add_helper_as_hash
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper({ controller: SettingsController, helper: SettingsHelper })

    assert loader.apply!
  end

  def test_add_helper_as_hash_as_string
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper({ controller: 'Settings', helper: 'Settings' })

    assert loader.apply!
  end

  def test_add_helper_as_hash_controller_only
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper({ controller: SettingsController })

    assert loader.apply!
  end

  def test_add_helper_as_hash_controller_only_string
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper({ controller: 'Settings' })

    assert loader.apply!
  end

  def test_require_files_for_lib
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id

    spec = File.join 'wiki_macros', '**/*_macro.rb'
    files = loader.require_files spec

    assert files.any?
    assert(files.detect { |file| file.include? 'test_macro' })
  end

  def test_plugin_dir
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id

    assert loader.plugin_dir.end_with? 'redmine_plugin_kit/test/redmine_test_plugin'
  end

  def test_require_files_for_app
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id

    spec = File.join 'helpers', "**/#{@plugin_id}_*.rb"
    files = loader.require_files spec, use_app: true

    assert files.any?
    assert(files.detect { |file| file.include? 'redmine_test_plugin_settings_helper' })
  end

  def test_apply_without_data
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id

    assert loader.apply!
  end

  def test_apply
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_helper 'Settings'
    loader.add_patch 'Issue'
    loader.add_global_helper RedmineTestPluginSettingsHelper

    assert loader.apply!
  end

  def test_do_not_allow_helper_if_controller_patch_exists
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch 'ProjectsController'
    loader.add_helper 'Projects'

    assert_raises RedminePluginKit::Loader::ExistingControllerPatchForHelper do
      assert loader.apply!
    end
  end

  def test_do_not_allow_helper_if_controller_patch_exists_as_hash
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.add_patch 'ProjectsController'
    loader.add_helper({ controller: ProjectsController, helper: 'Settings' })

    assert_raises RedminePluginKit::Loader::ExistingControllerPatchForHelper do
      assert loader.apply!
    end
  end

  def test_load_model_hooks
    hooks = RedminePluginKit::Loader.new(plugin_id: @plugin_id).load_model_hooks!

    assert_kind_of Module, hooks
  end

  def test_load_hooks
    hooks = RedminePluginKit::Loader.new(plugin_id: @plugin_id).load_view_hooks!

    assert_kind_of Module, hooks
  end

  def test_load_macros
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    macros = loader.load_macros!

    assert macros.any?
    assert(macros.detect { |macro| macro.include? 'test_macro' })
  end
end
