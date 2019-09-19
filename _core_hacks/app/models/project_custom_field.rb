# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ProjectCustomField < CustomField
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id", :autosave => true
  safe_attributes 'project_ids'
  def type_name
    :label_project_plural
  end

  def get_visible?(project = nil)
    if self.id
      id_column = self.id
      if self.visible && self.projects[0]  && project && project.id
        sql_statement = "SELECT 0 < (SELECT count(*) FROM `custom_fields` `ifa` WHERE `ifa`.`is_for_all` = 1 AND `ifa`.`id` = #{id_column}) OR
        (SELECT 1 FROM `custom_fields_projects` WHERE `custom_field_id` = #{id_column} AND `project_id` = '#{project.id}:') AS `visible`"
        rs = CustomField.connection.query(sql_statement)
        rs.each do |row|
=begin
          print("PROJECT:\n")
          print("#{project.id}\n")
=end
          if self.projects[0].id.to_s != project.id.to_s
            next
          end
=begin
          print("CUSTOM ROWs:\n")
          self.projects.each do |name|
            print("#{name[:id]}\n")
            print("#{name}\n")
          end
          print("ROW:\n")
          print("#{self.id}\n")
          print("#{self.project_ids}\n")
          print("#{id_column}\n")
          print("#{self.visible}\n")
          print("#{self.projects[0].id.to_s}\n")
=end
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

  def visibility_by_project_condition(project_key=nil, user=User.current, id_column=nil)
    sql = super
    id_column ||= id
    project_condition = "EXISTS (SELECT 1 FROM #{CustomField.table_name} ifa WHERE ifa.is_for_all = #{self.class.connection.quoted_true} AND ifa.id = #{id_column})" +
        " OR #{Project.table_name}.id IN (SELECT project_id FROM #{table_name_prefix}custom_fields_projects#{table_name_suffix} WHERE custom_field_id = #{id_column})"
    "((#{sql}) AND (#{project_condition}))"

    project_key ||= "#{Project.table_name}.id"
    super(project_key, user, id_column)
  end
end
