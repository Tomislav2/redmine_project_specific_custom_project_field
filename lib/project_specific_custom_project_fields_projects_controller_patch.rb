# noinspection RubyResolve
require_dependency 'projects_controller'

# noinspection RubyClassModuleNamingConvention
module ProjectSpecificCustomProjectFields
  module ProjectsControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        menu_item :projects, :only => [:index, :new, :copy, :copy_template, :create]
        before_action :find_project, :except => [ :index, :autocomplete, :list, :new, :create, :copy, :copy_template ]
        before_action :authorize, :except => [ :index, :autocomplete, :list, :new, :create, :copy, :copy_template, :archive, :unarchive, :destroy]
        before_action :authorize_global, :only => [:new, :copy_template, :create]
        before_action :require_admin, :only => [ :copy, :copy_template, :archive, :unarchive, :destroy ]
        accept_api_auth :index, :show, :copy_template, :create, :update, :destroy
        # noinspection RubyResolve
        unloadable

        alias_method :settings_custom_without_settings, :settings
        alias_method :settings, :settings_custom_with_settings
      end
    end

    # noinspection RubyTooManyInstanceVariablesInspection
    module InstanceMethods
      # noinspection RubyResolve,DuplicatedCode
      def settings_custom_with_settings
        logger.info("SETTINGS NEW:")
        logger.info(params)
        if params[:id]  == 'templates'
          redirect_to project_path(@project)
        end
        @issue_custom_fields = IssueCustomField.sorted.to_a
        @issue_category ||= IssueCategory.new
        @member ||= @project.members.new
        @trackers = Tracker.sorted.to_a
        @subprojects = @project.children.visible.to_a
        @version_status = params[:version_status] || 'open'
        @version_name = params[:version_name]
        @versions = @project.shared_versions.status(@version_status).like(@version_name).sorted
      end

      # noinspection RubyResolve
      def copy_template
        logger.info("COPY EXTENDED:")
        @issue_custom_fields = IssueCustomField.sorted.to_a
        @trackers = Tracker.sorted.to_a
        @source_project = Project.find(params[:id])
        @project = Project.copy_from(@source_project)
        @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
        if params[:commit]
          logger.info("PARAMS:")
          logger.info(params)
          Mailer.with_deliveries(params[:notifications] == '1') do
            logger.info("BEFORE NEW:")
           # @project = Project.new
            project_params = params[:project]
            # project_params[:template_id] = params[:id]
            logger.info("AFTER NEW:")
            logger.info(project_params)
            @project.safe_attributes = project_params
            logger.info("BEFORE COPY TRY:")
            if @project.copy(@source_project, :only => params[:only])
              flash[:notice] = l(:notice_successful_create)
              logger.info("NO-ERROR:")
              redirect_to settings_project_path(@project)
            elsif !@project.new_record?
              # Project was created
              # But some objects were not copied due to validation failures
              # (eg. issues from disabled trackers)
              # flash[:notice] = l(:notice_successful_create)
              # noinspection RubyResolve
              redirect_to settings_project_path(@project)
            end
          end
        end
        @subprojects = @project.children.visible.to_a
      rescue ActiveRecord::RecordNotFound
        # source_project not found
        render_404
      end
    end
  end
end

ProjectsController.send(:include, ProjectSpecificCustomProjectFields::ProjectsControllerPatch)
