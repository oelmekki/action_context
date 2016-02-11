require "action_context/version"

module ActionContext; end

require 'context_constantize'
require 'action_context/default_behavior'
require 'action_context/base'
require 'action_context/variant'
require 'action_context/helpers'
require 'action_context/railtie' if defined?( Rails::Railtie )

if defined? CanCan
  module CanCan
    class ControllerResource
      protected

      def build_resource
        resource = resource_base.new
        assign_attributes(resource)
      end
    end
  end
end
