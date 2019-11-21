
class Project < ActiveRecord::Base
  # noinspection DuplicatedCode
  @template_id = nil
  def available_custom_fields

    project_id_column = self.id
    project_condition = ''
    _project = project
    logger.info("\n\nProject - available_to_param\n")
    logger.info(project.attributes)
    logger.info(project.instance_variable_names)

    if @template_id
      project_template = Project.find_by_identifier([@template_id.to_s.downcase])
      project_id_column = project_template.id
      custom_values=project_template.custom_values.collect {|v| v.clone}
    else
      custom_values=project.custom_values.collect {|v| v.clone}
      custom_values.each do |custom_value|
        if custom_value.custom_field_id == 18
          project_template = Project.find_by_identifier([custom_value.value.downcase])
          if
          !self.id ||
              (
              project_template&.id &&
                  self.identifier &&
                  self.identifier.downcase.first(8) != "template"
              )
            project_id_column = project_template.id
          end
        end
      end
    end

    logger.info("\n\nProject - available_custom_fields\n")
    logger.info(project_id_column)
    logger.info("\n\nProject - available_custom_field_values\n")
    logger.info(custom_values)
    logger.info("\n\nProject - available_project_attributes\n")
    logger.info(project.attributes)



    if project_id_column
      project_condition = " AND ( ( is_for_all = 1) " +
          " OR #{project_id_column} IN (SELECT project_id FROM #{table_name_prefix}custom_fields_projects#{table_name_suffix} WHERE custom_field_id=id))"
    end

    CustomField.where("type = '#{self.class.name}CustomField'#{project_condition}").sorted.to_a
  end

  # Yields the given block for each project with its level in the tree
  def self.project_tree(projects, options={}, &block)
    ancestors = []
    if options[:init_level] && projects.first
      ancestors = projects.first.ancestors.to_a
    end
    projects.sort_by(&:lft).each do |project|

      if( project.identifier.downcase.first(8) == "template" )
        next
      end
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield project, ancestors.size
      ancestors << project
    end
  end


  # Yields the given block for each project with its level in the tree
  def self.project_template_tree(projects, options={}, &block)
    ancestors = []
    if options[:init_level] && projects.first
      ancestors = projects.first.ancestors.to_a
    end
    projects.sort_by(&:lft).each do |project|
      unless( project.identifier.downcase.first(8) == "template" )
        next
      end
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield project, ancestors.size
      ancestors << project
    end
  end

  # Copies and saves the Project instance based on the +project+.
  # Duplicates the source project's:
  # * Wiki
  # * Versions
  # * Categories
  # * Issues
  # * Members
  # * Queries
  #
  # Accepts an +options+ argument to specify what to copy
  #
  # Examples:
  #   project.copy(1)                                    # => copies everything
  #   project.copy(1, :only => 'members')                # => copies members only
  #   project.copy(1, :only => ['members', 'versions'])  # => copies members and versions
  def copy(project, options={})

    logger.info("\n\nProject - copy\n")
    logger.info(project)
    logger.info(options)

    project = project.is_a?(Project) ? project : Project.find(project)

    to_be_copied = %w(members wiki versions issue_categories issues queries boards documents)
    to_be_copied = to_be_copied & Array.wrap(options[:only]) unless options[:only].nil?

    Project.transaction do
      if save
        reload

        self.attachments = project.attachments.map do |attachment|
          attachment.copy(:container => self)
        end

        to_be_copied.each do |name|
          send "copy_#{name}", project
        end
        Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
        save
      else
        false
      end
    end
  end
  # Returns a new unsaved Project instance with attributes copied from +project+
  def self.copy_from(project)
    project = project.is_a?(Project) ? project : Project.find(project)
    # clear unique attributes
    logger.info("\n\nProject - copy_from - project.attributes:")
    logger.info(project.attributes)
    attributes = project.attributes.dup.except('id', 'name', 'identifier', 'status', 'parent_id', 'lft', 'rgt', 'template_id')
    logger.info("\n\nProject - copy_from - attributes:")
    logger.info(attributes)
    copy = Project.new(attributes)
    copy.enabled_module_names = project.enabled_module_names
    copy.trackers = project.trackers
    logger.info("\n\nProject - available_custom_values\n")
    copy_custom_values = project.custom_values.collect {|v| v.clone}
    logger.info(copy_custom_values)
    copy.custom_values = project.custom_values.collect {|v| v.clone}
    copy.issue_custom_fields = project.issue_custom_fields
    copy
  end


  def safe_attributes=(attrs, user=User.current)

    logger.info("\n\nProject - safe_attributes - attrs:")
    if attrs.respond_to?(:to_unsafe_hash)
      # noinspection RubyResolve
      attrs = attrs.to_unsafe_hash
    end
    return unless attrs.is_a?(Hash)
    attrs = attrs.deep_dup
    logger.info("\n\nProject - save - ATTR:")
    @template_id = attrs['template_id']
    logger.info("\n\nProject - TEMPLATE ID")
    logger.info(@template_id)
    logger.info("\n\nProject - save - ATTR after sshow:")
    logger.info(attrs)
    @unallowed_parent_id = nil
    if new_record? || attrs.key?('parent_id')
      parent_id_param = attrs['parent_id'].to_s
      if new_record? || parent_id_param != parent_id.to_s
        p = parent_id_param.present? ? Project.find_by_id(parent_id_param) : nil
        unless allowed_parents(user).include?(p)
          attrs.delete('parent_id')
          @unallowed_parent_id = true
        end
      end
    end
    super(attrs, user)
  end

end
