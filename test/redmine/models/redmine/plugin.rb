# frozen_string_literal: true

module Redmine
  class Plugin
    class << self
      def directory
        File.expand_path "#{File.dirname __FILE__}/../../../"
      end
    end
  end
end
