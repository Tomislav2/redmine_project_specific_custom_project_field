
class ProjectCustomField < CustomField

  # noinspection RailsParamDefResolve
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id", :autosave => true
  safe_attributes 'project_ids'
  # noinspection DuplicatedCode
  def get_visible?(project = nil)
    if self.id
      if self.visible && self.projects[0]  && project && project.id
        id_column = self.id
        project_id_column = project.id
        custom_values=project.custom_values.collect {|v| v.clone}
        custom_values.each do |custom_value|
          if custom_value.custom_field_id == 18
            project_template = Project.find_by_identifier([custom_value.value.downcase])
            if
            !self.id ||
                (
                project_template&.id &&
                    project_template.identifier &&
                    project_template.identifier.downcase.first(8) != "template"
                )
              project_id_column = project_template.id
            end
          end
        end
        logger.info("\n\nProjectCustomField - get_visible?\n")
        logger.info(project_id_column)
        sql_statement = "SELECT 0 < (SELECT count(*) FROM `custom_fields` `ifa` WHERE `ifa`.`is_for_all` = 1 AND `ifa`.`id` = #{id_column}) OR
        (SELECT 1 FROM `custom_fields_projects` WHERE `custom_field_id` = #{id_column} AND `project_id` = '#{project_id_column}:') AS `visible`"
        rs = CustomField.connection.query(sql_statement)
        rs.each do |row|
          if self.projects[0].id.to_s != project.id.to_s
            next
          end
          if row[0]
            return row[0].to_s == "1"
          end
        end
        return FALSE
      end
    end
  end

  def visible_by?(project, user=User.current)
    visible?(project) || user.admin?
  end

  def visible?(project=nil)
    get_visible?(project)
  end
  # Returns the error messages for the given value
  # or an empty array if value is a valid value for the custom field
  def validate_custom_value(custom_value)
    value = custom_value.value
    errs = format.validate_custom_value(custom_value)
    logger.info("VALIDATE CUSTOM VALUE !!!!!!")
    is_template = false
    if custom_value.customized
      logger.info(custom_value.customized.identifier)
      is_template = custom_value.customized.identifier.first(8) == 'template'
    end

    unless errs.any?
      if value.is_a?(Array)
        unless multiple?
          errs << ::I18n.t('activerecord.errors.messages.invalid')
        end
        unless is_template
          if is_required? && value.detect(&:present?).nil?
            errs << ::I18n.t('activerecord.errors.messages.blank')
          end
        end
      else
        unless is_template
          if is_required? && value.blank?
            errs << ::I18n.t('activerecord.errors.messages.blank')
          end
        end
      end
    end
    errs
  end
  def visibility_by_project_condition(project_key=nil, user=User.current, id_column=nil)
    sql = super
    id_column ||= id
    project_condition = " ( is_for_all = 1 AND id = #{id_column} )" +
        " OR #{Project.table_name}.id IN (SELECT project_id FROM #{table_name_prefix}custom_fields_projects#{table_name_suffix} WHERE custom_field_id = #{id_column})"
    "((#{sql}) AND (#{project_condition}))"
    logger.info("\n\nProjectCustomField - visibility_by_project_condition\n")
    logger.info(id_column)
    project_key ||= "#{Project.table_name}.id"
    super(project_key, user, id_column)
  end
end
