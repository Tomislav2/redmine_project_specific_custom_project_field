class ProjectSpecificFieldProjectMailer < Mailer

  helper :project_specific_field_projects

  def project_specific_field_project_added(project_specific_field_project)
    redmine_headers 'Project' => project_specific_field_project.project.identifier

    @author = project_specific_field_project.author
    @project_specific_field_project = project_specific_field_project
    @project_specific_field_project_url = url_for(controller: 'project_specific_field_projects', action: 'show', id: project_specific_field_project)

    message_id project_specific_field_project
    references project_specific_field_project

    mail to: project_specific_field_project.notified_users,
      subject: "#{l(:label_project_specific_field_project)}: #{project_specific_field_project.to_s}"
  end

  def project_specific_field_project_updated(project_specific_field_project)
    redmine_headers 'Project' => project_specific_field_project.project.identifier

    @author = project_specific_field_project.author
    @project_specific_field_project = project_specific_field_project
    @project_specific_field_project_url = url_for(controller: 'project_specific_field_projects', action: 'show', id: project_specific_field_project)

    message_id project_specific_field_project
    references project_specific_field_project

    mail to: project_specific_field_project.notified_users,
      subject: "#{l(:label_project_specific_field_project)}: #{project_specific_field_project.to_s}"
  end

end
