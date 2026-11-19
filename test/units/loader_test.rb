# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__
require File.expand_path '../redmine_test_plugin/redmine_test_plugin', __dir__

class LoaderTest < ActiveSupport::TestCase
  def setup
    @plugin_id = 'redmine_test_plugin'
    # The files to load again are kept on the class, so they have to be
    # cleared between tests - otherwise a probe of an earlier test fires again.
    RedminePluginKit::Loader.reloadable_files.clear
    ReloadProbe.reset!
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

  # A custom field format registers itself in a registry that lives on a module
  # Zeitwerk rebuilds on every reload. require would be a no-op the second time
  # round, which leaves the format unregistered after a code reload.
  def test_reload_on_prepare_loads_the_file_again_after_every_code_reload
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.reload_on_prepare probe_file('first')

    assert_empty ReloadProbe.loaded, 'registering must not load the file yet'

    reload_code

    assert_equal %w[first], ReloadProbe.loaded

    reload_code

    assert_equal %w[first first], ReloadProbe.loaded
  end

  # Without a code reload the class of the file is still there: loading it
  # again would define its constants twice ("already initialized constant").
  # This is the prepare run at boot, and every prepare run in production and
  # test, where code is never unloaded.
  def test_reload_on_prepare_does_not_load_the_file_without_a_code_reload
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.reload_on_prepare probe_file('first')

    ActiveSupport::Reloader.prepare!
    ActiveSupport::Reloader.prepare!

    assert_empty ReloadProbe.loaded
  end

  def test_reload_on_prepare_loads_the_file_once_for_several_prepare_runs_after_a_code_reload
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.reload_on_prepare probe_file('first')

    reload_code
    ActiveSupport::Reloader.prepare!

    assert_equal %w[first], ReloadProbe.loaded
  end

  # The setup of a plugin runs at boot and after every code reload, so it
  # registers its files again and again.
  def test_reload_on_prepare_loads_a_file_once_however_often_it_is_registered
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    3.times { loader.reload_on_prepare probe_file('first') }

    2.times do
      # the setup runs in the prepare run, before the files are loaded again
      unload_code
      loader.reload_on_prepare probe_file('first')
      ActiveSupport::Reloader.prepare!
    end

    assert_equal %w[first first], ReloadProbe.loaded
  end

  # Formats may inherit from each other (CompanyFormat < ContactFormat), so a
  # subclass loaded before its parent raises NameError.
  def test_reload_on_prepare_keeps_the_registration_order
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.reload_on_prepare probe_file('second')
    loader.reload_on_prepare probe_file('first')
    # a later setup run in another order does not change it
    loader.reload_on_prepare probe_file('first')
    loader.reload_on_prepare probe_file('second')

    reload_code

    assert_equal %w[second first], ReloadProbe.loaded
  end

  # A file that appears while the application runs is registered in the setup
  # after the code reload and loaded by its require there.
  def test_reload_on_prepare_does_not_load_a_file_registered_after_the_code_reload
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.reload_on_prepare probe_file('first')

    unload_code
    loader.reload_on_prepare probe_file('second')
    ActiveSupport::Reloader.prepare!

    assert_equal %w[first], ReloadProbe.loaded
  end

  def test_load_custom_field_format_requires_the_files_once_and_loads_them_after_a_code_reload
    forget_required_probes
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    # boot: setup, then the prepare run it is part of
    loader.load_custom_field_format!
    ActiveSupport::Reloader.prepare!

    assert_equal %w[first second], ReloadProbe.loaded

    # code reload: the setup runs again, its require is a no-op
    unload_code
    loader.load_custom_field_format!
    ActiveSupport::Reloader.prepare!

    assert_equal %w[first second first second], ReloadProbe.loaded
  end

  def test_load_custom_field_format_keeps_the_reverse_order_after_a_code_reload
    forget_required_probes
    loader = RedminePluginKit::Loader.new plugin_id: @plugin_id
    loader.load_custom_field_format! reverse: true
    reload_code

    assert_equal %w[second first second first], ReloadProbe.loaded
  end

  private

  def probe_file(name)
    File.join RedminePluginKit::Loader.new(plugin_id: @plugin_id).plugin_dir,
              'lib', @plugin_id, 'custom_field_formats', "#{name}_format.rb"
  end

  # What a code reload does: unload the classes, then prepare
  def reload_code
    unload_code
    ActiveSupport::Reloader.prepare!
  end

  def unload_code
    ActiveSupport::Reloader.new.run_callbacks :class_unload
  end

  # A probe required by an earlier test would not be loaded by require again
  def forget_required_probes
    $LOADED_FEATURES.delete probe_file('first')
    $LOADED_FEATURES.delete probe_file('second')
  end
end
