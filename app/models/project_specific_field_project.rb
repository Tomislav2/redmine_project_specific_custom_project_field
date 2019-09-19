class ProjectSpecificFieldProject < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, class_name: 'User'

  scope :visible, lambda { |*args|
    where(ProjectSpecificFieldProject.visible_condition(args.shift || User.current, *args)).joins(:project)
  }
  
  scope :sorted, lambda { order("#{table_name}.name ASC") }
  

  acts_as_searchable columns: ["#{ProjectSpecificFieldProject.table_name}.name"],
                     date_column: :created_at
  acts_as_customizable
  acts_as_attachable
  acts_as_event title: ->(o){"#{l(:label_project_specific_field_project)} - #{o.to_s}"},
    url: ->(o){{controller: 'project_specific_field_projects', action: 'show', id: o, project_id: o.project}},
    datetime: :created_at, description: :name
  acts_as_activity_provider author_key: :author_id, timestamp: "#{table_name}.created_at"

  validates :project_id, presence: true
  validates :author_id, presence: true


  safe_attributes *%w(name author_id custom_field_values custom_fields)
  safe_attributes 'project_id', if: ->(project_specific_field_project, _user) { project_specific_field_project.new_record? }

  after_create :send_create_notification
  after_update :send_update_notification

  def self.visible_condition(user, options = {})
    Project.allowed_to_condition(user, :view_project_specific_field_projects, options)
  end

  def self.css_icon
    'icon icon-user'
  end

  def editable_by?(user)
    visible?(user)
  end


  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:view_project_specific_field_projects, self.project, global: true)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_project_specific_field_projects, self.project, global: true)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_project_specific_field_projects, self.project, global: true)
  end

  def attachments_visible?(user = nil)
    visible?(user)
  end

  def attachments_editable?(user = nil)
    editable?(user)
  end

  def attachments_deletable?(user = nil)
    deletable?(user)
  end

  def to_s
    name.to_s
  end

  def created_on
    created_at
  end

  def updated_on
    updated_at
  end

  def notified_users
    if project
      project.notified_users.reject {|user| !visible?(user)}
    else
      [User.current]
    end
  end

  def send_create_notification
    # if Setting.notified_events.include?('project_specific_field_project_added')
    ProjectSpecificFieldProjectMailer.project_specific_field_project_added(self).deliver
    # end
  end

  def send_update_notification
    # if Setting.notified_events.include?('project_specific_field_project_updated')
    ProjectSpecificFieldProjectMailer.project_specific_field_project_updated(self).deliver
    # end
  end

end
