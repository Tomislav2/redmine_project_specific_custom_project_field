class AddShareWithSubprojectsToProjectSpecificCustomFieldsProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :project_specific_custom_fields_projects, :share_with_subprojects, :boolean, :default => true 
  end
end
