class ProjectSpecificFieldProjectQuery < Query

  self.queried_class = ProjectSpecificFieldProject

  def initialize_available_filters
    add_available_filter 'name', name: ProjectSpecificFieldProject.human_attribute_name(:name), type: :string
    if project.nil?
      add_available_filter 'project_id', name: ProjectSpecificFieldProject.human_attribute_name(:project_id), type: :list_optional, values: all_projects_values
    end
    add_available_filter 'author_id', name: ProjectSpecificFieldProject.human_attribute_name(:author_id), type: :list
    add_available_filter 'created_at', name: ProjectSpecificFieldProject.human_attribute_name(:created_at), type: :date
    add_available_filter 'updated_at', name: ProjectSpecificFieldProject.human_attribute_name(:updated_at), type: :date

    add_custom_fields_filters(ProjectSpecificFieldProjectCustomField)
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:name, caption: ProjectSpecificFieldProject.human_attribute_name(:name), title: ProjectSpecificFieldProject.human_attribute_name(:name), group: group)
    @available_columns << QueryColumn.new(:project, caption: ProjectSpecificFieldProject.human_attribute_name(:project_id), title: ProjectSpecificFieldProject.human_attribute_name(:project_id), group: group)
    @available_columns << QueryColumn.new(:author, caption: ProjectSpecificFieldProject.human_attribute_name(:author_id), title: ProjectSpecificFieldProject.human_attribute_name(:author_id), group: group)
    @available_columns << QueryColumn.new(:created_at, caption: ProjectSpecificFieldProject.human_attribute_name(:created_at), title: ProjectSpecificFieldProject.human_attribute_name(:created_at), group: group)
    @available_columns << QueryColumn.new(:updated_at, caption: ProjectSpecificFieldProject.human_attribute_name(:updated_at), title: ProjectSpecificFieldProject.human_attribute_name(:updated_at), group: group)
    @available_columns += ProjectSpecificFieldProjectCustomField.visible.collect { |cf| QueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { "name" => {:operator => "*", :values => []} }
  end

  def default_columns_names
    super.presence || ["name", "project", "author", "created_at"].flat_map{|c| [c.to_s, c.to_sym]}
  end

  def project_specific_field_projects(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = ProjectSpecificFieldProject.visible.
        where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    project_specific_field_projects = scope.to_a

    project_specific_field_projects
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
end
