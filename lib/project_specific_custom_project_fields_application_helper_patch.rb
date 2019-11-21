
module ApplicationHelper
  extend ApplicationHelper
  # Renders the projects index
  def render_project_hierarchy(projects)
    render_project_nested_lists(projects) do |project|
      s = link_to_project(project, {}, :class => "#{project.css_classes} #{User.current.member_of?(project) ? 'icon icon-fav my-project' : nil}")
      if project.description.present?
        s << content_tag('div', textilizable(project.short_description, :project => project), :class => 'wiki description')
      end
      s
    end
  end
  # Generates a link to a project settings if active
  # noinspection RubyInstanceMethodNamingConvention
  def identity_link_to_project_settings(project, options={}, html_options=nil)
    if project.active?
      link_to project.identifier, settings_project_path(project, options), html_options
    elsif project.archived?
      h(project.identifier)
    else
      link_to project.identifier, project_path(project, options), html_options
    end
  end

  def render_boards_tree(boards, parent=nil, level=0, &block)
    selection = boards.select {|b| b.parent == parent}
    return '' if selection.empty?

    s = ''.html_safe
    selection.each do |board|
      node = capture(board, level, &block)
      node << render_boards_tree(boards, board, level+1, &block)
      s << content_tag('div', node)
    end
    content_tag('div', s, :class => 'sort-level')
  end

  def project_tree_options_for_select(projects, options = {})
    s = ''.html_safe
    if (blank_text = options[:include_blank])
      if blank_text == true
        blank_text = '&nbsp;'.html_safe
      end
      s << content_tag('option', blank_text, :value => '')
    end
    project_tree(projects) do |project, level|
      if project.identifier.downcase.first(8) == "template"
        next
      end
      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => project.id}
      if project == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(project))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag_options.merge!(yield(project)) if block_given?
      s << content_tag('option', name_prefix + h(project), tag_options)
    end
    s.html_safe
  end
  # Yields the given block for each project with its level in the tree
  #
  # Wrapper for Project#project_template_tree
  def project_template_tree(projects, options={}, &block)
    Project.project_template_tree(projects, options, &block)
  end
  def get_parent_id
    (params[:project] && params[:project][:parent_id]) || params[:parent_id]
  end

  def get_parent(project)
    selected = project&.parent || nil
    # retrieve the requested parent project
    parent_id = get_parent_id
    if parent_id
      selected = (parent_id.blank? ? nil : Project.find(parent_id))
    end
    selected
  end

  def get_parent_is_template(project)
    get_parent_id == 'templates' || get_parent(project)&.identifier == 'templates'
  end

end
