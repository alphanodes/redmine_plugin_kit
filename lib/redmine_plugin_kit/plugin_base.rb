# frozen_string_literal: true

module RedminePluginKit
  module PluginBase
    def self.included(receiver)
      receiver.extend ClassMethods
    end

    module ClassMethods
      def setup!(existing_loader = nil)
        init_loader existing_loader
        raise "no loader for #{plugin_id}" if loader.nil?

        setup
      end

      def plugin_id
        to_s.underscore
      end

      def loader
        @loader ||= RedminePluginKit::Loader.new plugin_id: plugin_id
      end

      # support with default setting as fall back
      def setting(value)
        if settings.key? value
          settings[value]
        else
          loader.default_settings[value]
        end
      end

      def setting?(value)
        RedminePluginKit.true? setting(value)
      end

      private

      def init_loader(existing_loader)
        @loader = existing_loader
      end

      def settings
        Setting[:"plugin_#{plugin_id}"]
      end
    end
  end
end
