# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class ExtensionsTest < ActiveSupport::TestCase
  class Item
    extend RedminePluginKit::Extensions::Abstract

    abstract!

    def self.item_id
      name.demodulize.underscore
    end
  end

  class OwnItem < Item; end
  class OtherItem < Item; end

  class ChangedItem < OwnItem
    def self.item_id
      'own_item'
    end
  end

  class ConflictBase
    extend RedminePluginKit::Extensions::Abstract

    abstract!

    def self.conflict_key
      'same'
    end
  end

  def test_directories_of_all_plugins
    within_plugins do |root|
      dirs = RedminePluginKit::Extensions.directories 'items', plugin_dirs: plugin_dirs(root)

      assert_equal %W[#{root}/host/lib/items #{root}/other/lib/items], dirs
    end
  end

  def test_files_of_the_same_name_in_subdirectories_are_an_error
    within_plugins do |root|
      FileUtils.mkdir_p ["#{root}/host/lib/items/sub", "#{root}/other/lib/items/sub"]
      FileUtils.touch ["#{root}/host/lib/items/sub/same.rb", "#{root}/other/lib/items/sub/same.rb"]

      assert_raises RedminePluginKit::Extensions::DuplicateError do
        RedminePluginKit::Extensions.check_duplicates! ["#{root}/host/lib/items", "#{root}/other/lib/items"]
      end
    end
  end

  def test_directories_of_the_same_name_are_no_error
    within_plugins do |root|
      FileUtils.mkdir_p ["#{root}/host/lib/items/sub", "#{root}/other/lib/items/sub"]

      assert_nil RedminePluginKit::Extensions.check_duplicates!(["#{root}/host/lib/items", "#{root}/other/lib/items"])
    end
  end

  def test_files_of_the_same_name_are_an_error
    within_plugins do |root|
      FileUtils.touch "#{root}/other/lib/items/own_item.rb"

      assert_raises RedminePluginKit::Extensions::DuplicateError do
        RedminePluginKit::Extensions.check_duplicates! ["#{root}/host/lib/items", "#{root}/other/lib/items"]
      end
    end
  end

  def test_declarations_of_a_plugin_are_merged
    within_plugins do |root|
      declared = {}
      declare root, 'other', %w[items], declared: declared
      declare root, 'other', %i[widgets items], declared: declared

      assert_equal %w[items widgets], declared['other']
    end
  end

  # Only load! of the host loads a declared directory, so without the host
  # nothing does
  def test_declared_directory_is_not_eager_loaded
    within_plugins do |root|
      assert_not_includes loaded(root, { 'other' => %w[items] }, &:eager_load), 'OtherItem'
    end
  end

  def test_load_loads_declared_directories
    within_plugins do |root|
      loaded_classes = loaded root, 'other' => %w[items] do |loader|
        RedminePluginKit::Extensions.load! 'items', plugin_dirs: plugin_dirs(root), loader: loader,
                                                    declared: { 'other' => %w[items] }
      end

      assert_equal %w[OtherItem OwnItem], loaded_classes.sort
    end
  end

  def test_load_marks_the_point_as_loaded
    within_plugins do |root|
      loaded root, 'other' => %w[items] do |loader|
        RedminePluginKit::Extensions.load! 'loaded_probe', plugin_dirs: plugin_dirs(root), loader: loader, declared: {}
      end

      assert RedminePluginKit::Extensions.loaded?('loaded_probe')
    end
  end

  def test_point_without_load_is_not_loaded
    assert_not RedminePluginKit::Extensions.loaded?('never_loaded_probe')
  end

  def test_undeclared_point_of_an_installed_host_stops_loading
    within_plugins do |root|
      error = assert_raises RedminePluginKit::Extensions::UndeclaredError do
        RedminePluginKit::Extensions.load! 'items', plugin_dirs: plugin_dirs(root), loader: Zeitwerk::Loader.new, declared: {}
      end

      assert_includes error.message, 'loader.extends %w[items]'
    end
  end

  def test_undeclared_directory_without_classes_is_no_error
    within_plugins do |root|
      FileUtils.rm "#{root}/other/lib/items/other_item.rb"

      assert_nil RedminePluginKit::Extensions.check_declared!('items', plugin_dirs(root), {})
    end
  end

  def test_undeclared_dirs_without_a_host
    within_plugins do |root|
      FileUtils.rm_rf "#{root}/host"
      write_class "#{root}/other/lib/widgets/plain_widget.rb", 'Widgets', 'PlainWidget'

      assert_equal %w[widgets], undeclared(root, declared: { 'other' => %w[items] })
    end
  end

  def test_undeclared_dirs_leave_out_directories_with_their_module
    within_plugins do |root|
      assert_empty RedminePluginKit::Extensions.undeclared_dirs("#{root}/host", declared: {})
    end
  end

  def test_undeclared_dirs_leave_out_directories_without_classes
    within_plugins do |root|
      FileUtils.mkdir_p "#{root}/other/lib/tasks"
      FileUtils.touch "#{root}/other/lib/tasks/other.rake"

      assert_empty undeclared(root, declared: { 'other' => %w[items] })
    end
  end

  def test_undeclared_dirs_leave_out_standalone_directories
    within_plugins do |root|
      write_class "#{root}/other/lib/searches/plain_search.rb", 'Searches', 'PlainSearch'

      assert_empty undeclared(root, standalone: %w[searches], declared: { 'other' => %w[items] })
    end
  end

  def test_undeclared_dirs_reject_a_standalone_name_without_a_directory
    within_plugins do |root|
      assert_raises ArgumentError do
        undeclared root, standalone: %w[searches], declared: { 'other' => %w[items] }
      end
    end
  end

  def test_undeclared_dirs_reject_a_standalone_name_that_is_declared
    within_plugins do |root|
      assert_raises ArgumentError do
        undeclared root, standalone: %w[items], declared: { 'other' => %w[items] }
      end
    end
  end

  def test_classes_without_base_classes
    assert_equal [ExtensionsTest::ChangedItem, ExtensionsTest::OtherItem, ExtensionsTest::OwnItem],
                 RedminePluginKit::Extensions.classes(Item).sort_by(&:name)
  end

  # A plugin changes the extension of another one by a subclass with its key
  def test_subclass_with_the_same_key_replaces_its_superclass
    assert_equal [ExtensionsTest::ChangedItem, ExtensionsTest::OtherItem],
                 RedminePluginKit::Extensions.classes(Item, key: :item_id).sort_by(&:name)
  end

  def test_unrelated_classes_with_the_same_key_are_an_error
    first = Class.new ConflictBase
    second = Class.new ConflictBase
    first.define_singleton_method(:name) { 'First' }
    second.define_singleton_method(:name) { 'Second' }

    assert_raises RedminePluginKit::Extensions::ConflictError do
      RedminePluginKit::Extensions.classes ConflictBase, key: :conflict_key
    end
  end

  private

  def plugin_dirs(root)
    Dir.glob "#{root}/*"
  end

  def declare(root, plugin_id, points, loader: Zeitwerk::Loader.new, declared: {})
    RedminePluginKit::Extensions.declare "#{root}/#{plugin_id}", points, loader: loader, declared: declared
  end

  def undeclared(root, **)
    RedminePluginKit::Extensions.undeclared_dirs("#{root}/other", **)
  end

  # The classes the block loads from lib/ of all plugins, declared in the
  # order of Redmine: init.rb runs after the setup of Zeitwerk
  def loaded(root, declared)
    ReloadProbe.reset!
    loader = Zeitwerk::Loader.new
    loader.enable_reloading
    plugin_dirs(root).each { |dir| loader.push_dir "#{dir}/lib" }
    loader.setup
    declared.each { |plugin_id, points| declare root, plugin_id, points, loader: loader }
    yield loader
    ReloadProbe.loaded.dup
  ensure
    loader.unload
    loader.unregister
  end

  def write_class(path, namespace, name)
    FileUtils.mkdir_p File.dirname(path)
    File.write path, "module #{namespace}\n  class #{name}; end\nend\nReloadProbe.loaded << '#{name}'\n"
  end

  # host with the module items.rb, other with an item for host
  def within_plugins
    Dir.mktmpdir do |root|
      File.write "#{root}/host/lib/items.rb".tap { |f| FileUtils.mkdir_p File.dirname(f) }, "module Items; end\n"
      write_class "#{root}/host/lib/items/own_item.rb", 'Items', 'OwnItem'
      write_class "#{root}/other/lib/items/other_item.rb", 'Items', 'OtherItem'
      yield root
    end
  end
end
