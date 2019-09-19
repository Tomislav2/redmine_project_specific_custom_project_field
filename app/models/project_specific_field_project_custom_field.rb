class ProjectSpecificFieldProjectCustomField < CustomField

  def type_name
    :label_project_specific_field_projects
  end

  def form_fields
    [:is_filter, :searchable, :is_required]
  end

end
