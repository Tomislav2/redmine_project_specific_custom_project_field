
class ProjectCustomField < CustomField

  # noinspection RailsParamDefResolve
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id", :autosave => true
  safe_attributes 'project_ids'
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
    logger.info("NOT VALIDATE CUSTOM VALUE IF DIRTY !!!!")
    logger.info(custom_value.customized.is_dirty)
    unless errs.any?
      if value.is_a?(Array)
        unless multiple?
          errs << ::I18n.t('activerecord.errors.messages.invalid')
        end
        unless is_template || custom_value.customized.is_dirty
          if is_required? && value.detect(&:present?).nil?
            errs << ::I18n.t('activerecord.errors.messages.blank')
          end
        end
      else
        unless is_template || custom_value.customized.is_dirty
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
