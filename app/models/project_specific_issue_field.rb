class ProjectSpecificIssueField < CustomField
  unloadable
  
  attr_accessor 'project'
  
  validates_presence_of 'project'
  after_initialize 'initialize_project'
  after_create 'create_projects'
  has_one :project_specific_custom_fields_project, :dependent => :destroy, :foreign_key => 'custom_field_id'

  def type_name
    :label_project_specific_issue_plural
  end
  
  validate do
    #if we get an error that the name has already been taken, and it is the only name error,
    # delete it if it is unique for the project
    errors.each do |attribute, error|
      if attribute == :name and errors.get(attribute).size == 1 and error == "has already been taken" and name_unique_for_project?()
        errors.delete(attribute)
      end
    end
  end
  
  def initialize_project
    cfp = ProjectSpecificCustomFieldsProject.where(:custom_field_id => self.id).first unless self.id.nil?
    self.project = cfp.project unless cfp.nil?
  end
  
  def create_projects
    self.project.project_specific_issue_custom_fields << self
    self.project.save
  end
  
  private
  def name_unique_for_project?()
    for f in IssueCustomField.all + self.project.project_specific_issue_custom_fields
      if (self.name == f.name) and (self.field_format == f.field_format)
        return false
      end
    end
    true
  end
  
end
