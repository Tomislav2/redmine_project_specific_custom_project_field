module ProjectSpecificFieldProjectsHelperPatch
  def self.included(base)
    unloadable
    
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method :project_settings_tabs_without_project_specific_tab, :project_settings_tabs
      alias_method :project_settings_tabs, :project_settings_tabs_with_project_specific_tab
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end
  
  def project_settings_tabs_with_project_specific_tab
    tabs = project_settings_tabs_without_project_specific_tab
    tabs << {:name => 'custom_fields', :action => :manage_project_activities, :partial => 'projects/settings/custom_fields', :label => :label_custom_field_plural} if User.current.allowed_to?(:manage_project_custom_fields, @project)
    tabs
  end
  
end

ProjectsHelper.send(:include, ProjectSpecificFieldProjectsHelperPatch) unless ProjectsHelper.included_modules.include? ProjectSpecificFieldProjectsHelperPatch