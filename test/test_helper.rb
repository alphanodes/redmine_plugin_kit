# frozen_string_literal: true

require 'rails/all'
require 'redmine_plugin_kit'
require 'minitest/autorun'

# ActiveRecord::Base.logger = Logger.new $stdout
ActiveRecord::Base.configurations = YAML.load_file "#{File.dirname __FILE__}/database.yml"
ActiveRecord::Base.establish_connection :test

load "#{File.dirname __FILE__}/schema.rb"
Dir.glob(File.expand_path('../redmine/controllers/*.rb', __FILE__)).sort.each { |f| require f }
Dir.glob(File.expand_path('../redmine/models/*.rb', __FILE__)).sort.each { |f| require f }
Dir.glob(File.expand_path('../redmine/helpers/*.rb', __FILE__)).sort.each { |f| require f }

module ActiveSupport
  class TestCase
    include ActiveRecord::TestFixtures

    self.fixture_path = "#{File.dirname __FILE__}/fixtures/"

    self.use_transactional_tests = true
    self.use_instantiated_fixtures = false
    fixtures :all
  end
end
