# frozen_string_literal: true

module RedminePluginKit
  # Classes one plugin (the host) collects from all plugins, a file per class
  # and no list naming them, e.g. dashboard blocks:
  #
  # - every plugin keeps them in lib/<point>/; the host also has the module
  #   lib/<point>.rb, which makes it the host
  # - any other plugin declares the point in its init.rb with
  #   loader.extends %w[<point>]. Zeitwerk then never eager loads its
  #   lib/<point>/, only load! of the host loads it, so without the host the
  #   files need no guard against a missing base class. They stay autoloadable
  #   though: nothing outside lib/<point>/ may refer to their constants, and
  #   defined?(<Point>) is no test for the host.
  #
  # The host loads them with load! and gets them with classes, which reads
  # only what load! loaded: read them at runtime, not in the setup of a plugin,
  # as the setups run in plugin order.
  module Extensions
    # Zeitwerk loads only one of two files of the same name in different
    # plugins and drops the other one silently
    class DuplicateError < StandardError; end

    # Two classes with the same key, neither a subclass of the other
    class ConflictError < StandardError; end

    # A plugin has lib/<point>/ of another plugin without declaring it: without
    # that plugin installed, its files would fail on the missing base class
    class UndeclaredError < StandardError; end

    # For the base classes of a point, which are no extension themselves
    module Abstract
      def abstract!
        @abstract = true
      end

      # Not inherited: a subclass of a base class is an extension
      def abstract?
        @abstract == true
      end
    end

    class << self
      # Called from init.rb (see Loader#extends). Redmine runs it in
      # to_prepare, after Zeitwerk is set up, so ignoring is too late there,
      # but it runs before eager loading.
      def declare(plugin_dir, points, loader: Rails.autoloaders.main, declared: declarations)
        plugin_id = File.basename plugin_dir.to_s
        points = Array(points).map(&:to_s)
        declared[plugin_id] = declared.fetch(plugin_id, []) | points

        points.each { |point| loader.do_not_eager_load File.join(plugin_dir.to_s, 'lib', point) }
      end

      # Points by plugin id
      def declarations
        @declarations ||= {}
      end

      # For a convention test of a plugin: directories in lib/ with classes but
      # no module lib/<name>.rb, which are neither declared nor named as
      # standalone. Unlike the check at boot, it needs no host installed.
      def undeclared_dirs(plugin_dir, standalone: [], declared: declarations)
        plugin_dir = plugin_dir.to_s
        lib = File.join plugin_dir, 'lib'
        candidates = File.directory?(lib) ? Dir.children(lib).select { |name| guest_dir? plugin_dir, name } : []
        standalone = standalone.map(&:to_s)
        points = declared.fetch File.basename(plugin_dir), []

        # A stale entry would hide a directory added later under its name
        check_standalone! standalone - candidates, 'names no directory with classes and without a module'
        check_standalone! standalone & points, 'names a point declared with loader.extends'

        (candidates - points - standalone).sort
      end

      # Loads the classes of all plugins; call it from the setup of the host,
      # which runs at boot and after every code reload
      # Declared directories are excluded from eager loading, so each file is
      # loaded on its own (load_file honours no exclusion, unlike
      # eager_load_dir, which would skip them silently).
      def load!(point, plugin_dirs: redmine_plugin_dirs, loader: Rails.autoloaders.main, declared: declarations)
        check_declared! point, plugin_dirs, declared
        dirs = directories point, plugin_dirs: plugin_dirs
        check_duplicates! dirs
        dirs.each do |dir|
          Dir.glob('**/*.rb', base: dir).each { |file| loader.load_file File.join(dir, file) }
        end
        loaded_points << point.to_s
      end

      # Whether load! ran for the point; until then classes would miss the
      # extensions of all plugins
      def loaded?(point)
        loaded_points.include? point.to_s
      end

      # Runs from load!, after the init.rb of all plugins
      def check_declared!(point, plugin_dirs, declared)
        undeclared = plugin_dirs.select { |dir| guest_dir?(dir, point) && declared.fetch(File.basename(dir), []).exclude?(point) }
        return if undeclared.empty?

        raise UndeclaredError,
              "lib/#{point} of #{undeclared.map { |dir| File.basename dir }.join ', '} is not declared, " \
              "add to init.rb: loader.extends %w[#{point}]"
      end

      def directories(point, plugin_dirs: redmine_plugin_dirs)
        candidates = plugin_dirs.map { |plugin_dir| File.join plugin_dir, 'lib', point }
        candidates.select! { |dir| File.directory? dir }
        candidates
      end

      # Directories of the same name are fine, Zeitwerk merges them
      def check_duplicates!(dirs)
        duplicates = dirs.flat_map { |dir| Dir.glob '**/*.rb', base: dir }.tally.select { |_file, count| count > 1 }.keys
        raise DuplicateError, "In several plugins: #{duplicates.join ', '}" if duplicates.any?
      end

      # The loaded subclasses of a base, without base classes and anonymous
      # classes (e.g. of tests). With a key (e.g. :block_id) classes with the
      # same key are one extension: a subclass replaces its superclass, so a
      # plugin can change an extension of another one.
      def classes(base, key: nil)
        found = base.descendants.reject { |klass| klass.abstract? || klass.name.nil? }
        return found unless key

        found.group_by(&key).map { |value, same_key| most_specific value, same_key }
      end

      private

      def loaded_points
        @loaded_points ||= Set.new
      end

      def check_standalone!(names, problem)
        raise ArgumentError, "standalone #{problem}: #{names.join ', '}" if names.any?
      end

      # lib/<name>/ with classes, but without the module of a host
      def guest_dir?(plugin_dir, name)
        dir = File.join plugin_dir, 'lib', name
        File.directory?(dir) && !File.file?("#{dir}.rb") && Dir.glob('**/*.rb', base: dir).any?
      end

      def most_specific(value, classes)
        found = classes.detect { |candidate| classes.all? { |other| candidate <= other } }
        raise ConflictError, "#{value}: #{classes.map(&:name).join ', '}" unless found

        found
      end

      def redmine_plugin_dirs
        Redmine::PluginLoader.directories.map(&:to_s)
      end
    end
  end
end
