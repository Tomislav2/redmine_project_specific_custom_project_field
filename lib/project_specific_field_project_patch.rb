module ProjectSpecificFieldProjectPatch
  def self.included(base)
    unloadable
    
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method :all_project_custom_fields_without_project_specific, :available_custom_fields
      alias_method :available_custom_fields, :all_project_custom_fields_with_project_specific
=begin
      alias_method :project_custom_field_value_without_custom_field_value, :custom_field_value
      alias_method :custom_field_value, :project_custom_field_value_with_custom_field_value
=end
      has_and_belongs_to_many :project_specific_project_custom_fields,
                              :class_name => 'ProjectCustomField',
                              :order => "#{CustomField.table_name}.position",
                              :join_table => "#{table_name_prefix}project_specific_custom_fields_projects#{table_name_suffix}",
                              :association_foreign_key => 'custom_field_id'
                              
      before_destroy :destroy_project_specific_custom_fields
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def recursive_project_specific_project_fields
      fields = []
      fields += self.parent.recursive_project_specific_project_fields_from_parent unless self.parent.nil?
      fields + self.project_specific_project_custom_fields.sorted.all
    end
    
    def recursive_project_specific_project_fields_from_parent
      fields = []
      fields += self.parent.recursive_project_specific_project_fields_from_parent unless self.parent.nil?
      fields += self.project_specific_project_custom_fields.where('project_specific_custom_fields_projects.share_with_subprojects' => true).sorted.all
      fields
    end
  end
  
  def destroy_project_specific_custom_fields
    project_specific_project_custom_fields.each do |f|
      f.destroy()
    end
  end

  def all_project_custom_fields_with_project_specific
    all_project_custom_fields = all_project_custom_fields_without_project_specific 
    all_project_custom_fields ||= self.project_specific_project_custom_fields
    all_project_custom_fields
  end

=begin
  def project_custom_field_value_with_custom_field_value
    project_custom_field_value = project_custom_field_value_without_custom_field_value
    project_custom_field_value ||= self.custom_field_value
    project_custom_field_value
  end
=end
end

Project.send(:include, ProjectSpecificFieldProjectPatch) unless Project.included_modules.include? ProjectSpecificFieldProjectPatch