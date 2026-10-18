# frozen_string_literal: true

# The plugin directory of Redmine, as Redmine::PluginLoader uses it: tests may
# point it elsewhere (REDMINE_PLUGINS_DIRECTORY), so not always plugins/
plugins_dir = Rails.root.join(Rails.application.config.try(:redmine_plugins_directory) || 'plugins')

Rails.application.paths['app/overrides'] ||= []
plugins_dir.glob('*/app/overrides').each do |path|
  Rails.application.paths['app/overrides'] << path unless Rails.application.paths['app/overrides'].include? path
end

plugins_dir.glob('*/app/overrides/**/*.deface').each do |path|
  Deface::DSL::Loader.load path.to_s
end
