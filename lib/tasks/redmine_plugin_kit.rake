# frozen_string_literal: true

namespace :redmine_plugin_kit do
  desc <<-DESCRIPTION
  Drop plugin settings.

  Example:
    bundle exec rake redmine_plugin_kit:drop_settings RAILS_ENV=production plugin="redmine_plugin_example"
  DESCRIPTION
  task drop_settings: :environment do
    plugin = ENV.fetch 'plugin', nil

    if plugin.blank?
      puts 'Parameter plugin is required.'
      exit 2
    end

    Setting.where(name: :"plugin_#{plugin}").destroy_all
    Setting.clear_cache
    puts "Setting for plugin #{plugin} has been dropped."
  end

  desc <<-DESCRIPTION
  Set settings.

  Example for value:
    bundle exec rake redmine_plugin_kit:setting_set RAILS_ENV=production name="additionals" setting="open_external_urls" value="1"
  Example for list of value:
    bundle exec rake redmine_plugin_kit:setting_set RAILS_ENV=production setting="default_projects_modules" value="issue_tracking,time_tracking,wiki"
  DESCRIPTION
  task setting_set: :environment do
    name = ENV['name'] ||= 'redmine'
    setting = ENV.fetch 'setting', nil
    value = if ENV['values'].present?
              ENV['values'].split ','
            else
              ENV.fetch 'value', nil
            end

    if name.blank? || setting.blank? || value.blank?
      puts 'Parameters setting and value are required.'
      exit 2
    end

    if name == 'redmine'
      Setting[setting.to_sym] = value
    else
      plugin_name = :"plugin_#{name}"
      plugin_settings = Setting[plugin_name]
      plugin_settings[setting] = value
      Setting[plugin_name] = plugin_settings
    end
  end

  desc <<-DESCRIPTION
  Get settings.

  Example for plugin setting:
    bundle exec rake redmine_plugin_kit:setting_get RAILS_ENV=production name="additionals" setting="open_external_urls"
  Example for redmine setting:
    bundle exec rake redmine_plugin_kit:setting_get RAILS_ENV=production name="redmine" setting="app_title"
  Example for redmine setting:
    bundle exec rake redmine_plugin_kit:setting_get RAILS_ENV=production setting="app_title"
  DESCRIPTION
  task setting_get: :environment do
    name = ENV['name'] ||= 'redmine'
    setting = ENV.fetch 'setting', nil

    if setting.blank?
      puts 'Parameters setting is required'
      exit 2
    end

    if name == 'redmine'
      puts Setting.send(setting)
    else
      plugin_name = :"plugin_#{name}"
      plugin_settings = Setting[plugin_name]
      puts plugin_settings[setting]
    end
  end

  desc 'Detects templates from the plugin that override Redmine core templates'
  task detect_overwritten_templates: :environment do
    redmine_views_root = Rails.root.join 'app/views'

    Rails.root.glob('plugins/*').each do |plugin_path|
      plugin_path = plugin_path.to_s
      plugin_views = Dir.glob "#{plugin_path}/app/views/**/*.{erb,slim}"
      overwritten = []

      plugin_views.each do |plugin_file|
        relative_path = plugin_file.sub %r{^#{Regexp.escape plugin_path}/app/views/}, ''
        base_path = relative_path.sub(/\.(erb|slim)$/, '')
        redmine_template = redmine_views_root.join "#{base_path}.erb"

        overwritten << "app/views/#{base_path}.erb" if File.exist? redmine_template
      end

      output_file = File.join plugin_path, '.overwritten_templates'
      previous_content = if File.exist? output_file
                           lines = File.read(output_file).lines.map(&:strip)
                           lines.sort
                         else
                           []
                         end
      new_content = overwritten.sort

      if previous_content == new_content
        puts "✔️  No changes for: #{File.basename plugin_path}"
      else
        File.write output_file, "#{new_content.join "\n"}\n"
        puts "✅ Updated: #{output_file}"
      end
    end
  end
end
