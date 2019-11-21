
module Redmine
  module Acts
    module Customizable
      extend Customizable
      # noinspection DuplicatedCode
      def available_custom_fields
        classname = self.class.name
        extra_condition = ''
        if classname == 'Project'
          project_id_column = self.id
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

          if project_id_column
            project_condition = " AND ( (is_for_all = 1 ) " +
                " OR #{project_id_column} IN (SELECT project_id FROM #{table_name_prefix}custom_fields_projects#{table_name_suffix} WHERE custom_field_id=id))"
            extra_condition = project_condition
            logger.info("\n\nCustomizable Project - available_custom_fields\n")
            logger.info(project_id_column)
          end

        end
        CustomField.where("type = '#{self.class.name}CustomField'#{extra_condition}").sorted.to_a
      end
    end
  end
end


