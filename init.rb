require 'redmine'

Rails.logger.info 'o:=>'
Rails.logger.info 'o:=> Starting Redmine Project Specific Custom Project Fields Plugin for Redmine'


Redmine::Plugin.register :redmine_project_specific_custom_project_fields do
  name 'Redmine Project Specific Custom Project Fields plugin'
  author 'Tomislav Kramaric'
  version '0.0.1'
  description 'Add the ability to create project specific custom project fields'
  url 'https://github.com/Tomislav2/redmine_project_specific_custom_project_field'
  author_url 'https://www.tomislav.net'
  requires_redmine :version_or_higher => '4'
end


Rails.application.config.to_prepare do
  require_dependency 'project_specific_custom_project_fields_acts_as_customizable_patch'
  require_dependency 'project_specific_custom_project_fields_application_helper_patch'
  require_dependency 'project_specific_custom_project_fields_projects_helper_patch'
  require_dependency 'project_specific_custom_project_fields_custom_field_value_patch'
  require_dependency 'project_specific_custom_project_fields_pricipal_patch'
  require_dependency 'project_specific_custom_project_fields_project_custom_field_patch'
  require_dependency 'project_specific_custom_project_fields_project_patch'
  require_dependency 'project_specific_custom_project_fields_projects_controller_patch'
end
