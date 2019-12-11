
module ProjectsHelper
  extend ProjectsHelper

  # Renders the projects index
  def render_project_hierarchy(projects)
    logger.info("render project hierarchy".upcase)

    _projects = []

    projects.each do |project|
      if project.identifier.downcase.first(8) == "template"
        next
      end
      _projects << project
    end

    render_project_nested_lists(_projects) do |project|
      logger.info(project.identifier.downcase)
      s = link_to_project(project, {}, :class => "#{project.css_classes} #{User.current.member_of?(project) ? 'icon icon-fav my-project' : nil}")
      if project.description.present?
        s << content_tag('div', textilizable(project.short_description, :project => project), :class => 'wiki description')
      end
      s
    end
  end

  def parent_project_select_tag(project)
    selected = get_parent(project)
    options = ''
    options << "<option value=''>&nbsp;</option>" if project.allowed_parents.include?(nil)
    options << project_tree_options_for_select(project.allowed_parents.compact, :selected => selected)
    content_tag('select', options.html_safe, :name => 'project[parent_id]', :id => 'project_parent_id')
  end
end