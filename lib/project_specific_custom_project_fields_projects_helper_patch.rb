
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

  def find_template_project
    Project.find('templates')
  rescue ActiveRecord::RecordNotFound
    @project = Project.new
    @project.safe_attributes= {:custom_field_values =>{}, :name =>"Templates", :description =>"Templates", :identifier =>"templates", :is_public =>"0", :parent_id =>"", :enabled_module_names =>[""], :tracker_ids =>[]}
    if @project.save
      @project1 = Project.new
      @project1.safe_attributes= {:custom_field_values =>{}, :name =>"Template1", :description =>"Template1", :identifier =>"template1", :is_public =>"0", :parent_id =>Project.find('templates').id, :enabled_module_names =>[""], :tracker_ids =>[]}
      if @project1.save
        Project.find('templates')
      else
        nil
      end
    else
      nil
    end
  end
end