
module ProjectsHelper
  extend ProjectsHelper

  def parent_project_select_tag(project)
    selected = get_parent(project)
    options = ''
    options << "<option value=''>&nbsp;</option>" if project.allowed_parents.include?(nil)
    options << project_tree_options_for_select(project.allowed_parents.compact, :selected => selected)
    content_tag('select', options.html_safe, :name => 'project[parent_id]', :id => 'project_parent_id')
  end
end