# frozen_string_literal: true

Rails.application.paths['app/overrides'] ||= []
Dir[Rails.root.join('plugins/*/app/overrides')].each do |dir|
  Rails.application.paths['app/overrides'] << dir unless Rails.application.paths['app/overrides'].include? dir
end

Rails.root.glob('plugins/*/app/overrides/**/*.deface').each do |path|
  Deface::DSL::Loader.load File.expand_path(path, __FILE__)
end
