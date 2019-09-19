require_dependency 'project_specific_field_project_patch'
require_dependency 'project_specific_field_query_patch'
require_dependency 'project_specific_field_projects_helper_patch'

Redmine::Plugin.register :redmine_project_specific_custom_field do
  permission :manage_project_custom_fields, :project_specific_fields => [ :index, :edit, :show, :update, :create, :new, :create_link ]
  permission :delete_project_custom_fields, :project_specific_fields => [ :destroy ]
    
  name 'Redmine Project Specific Field plugin'
  author 'Tomislav Kramaric'
  version '0.0.1'
  description 'Add the ability to create project specific custom fields'
  url 'https://github.com/Tomislav2/redmine_project_specific_custom_field'
  author_url 'https://www.tomislav.net'
end
