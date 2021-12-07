# frozen_string_literal: true

module RedmineTestPlugin
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def new_dummy_method; end
      end
    end
  end
end
