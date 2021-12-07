# frozen_string_literal: true

Rails.application.paths['app/overrides'] ||= []
Dir.glob(Rails.root.join('plugins/*/app/overrides')).each do |dir|
  Rails.application.paths['app/overrides'] << dir unless Rails.application.paths['app/overrides'].include? dir
end
