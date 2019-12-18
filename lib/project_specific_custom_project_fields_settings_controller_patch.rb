# noinspection RubyResolve
require_dependency 'settings_controller'

# noinspection RubyClassModuleNamingConvention
module ProjectSpecificCustomProjectFields
  module SettingsControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        layout 'admin'
        self.main_menu = false
        menu_item :plugins, :only => :plugin
        helper :queries
        before_action :require_admin
        require_sudo_mode :index, :edit, :plugin

        # noinspection RubyResolve
        unloadable

        before_action :plugin_with_plugin, :only => :plugin
      end
    end

    # noinspection RubyTooManyInstanceVariablesInspection
    module InstanceMethods

      def plugin_with_plugin
        if request.post? and params[:id] == 'redmine_project_specific_custom_project_fields' && params[:settings][:template_custom_names]
          params[:settings][:template_custom_names].each do |key|
            if key.first && key.second
=begin
              logger.info(key.first)
              logger.info(key.second)
=end
              @template = Project.find_by_identifier(key.first)
              @template.name = key.second
              @template.name.to_s.trim!
              @template.save
            end
          end
        end
      end
    end
  end
end

SettingsController.send(:include, ProjectSpecificCustomProjectFields::SettingsControllerPatch)
