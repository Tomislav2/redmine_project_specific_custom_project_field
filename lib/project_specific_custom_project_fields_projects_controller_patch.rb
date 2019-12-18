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

        alias_method :settings, :settings_custom_with_settings
        alias_method :update, :update_custom_with_update

        alias_method :authorize_custom_without_authorize, :authorize
        alias_method :authorize, :authorize_custom_with_authorize

        alias_method :require_login_custom_without_require_login, :require_login
        alias_method :require_login, :require_login_custom_with_require_login
      end
    end

    #noinspection RubyTooManyInstanceVariablesInspection,RubyInstanceMethodNamingConvention
    module InstanceMethods
      # noinspection RubyResolve,DuplicatedCode
      def settings_custom_with_settings
        # logger.info("SETTINGS NEW:")
        # logger.info(params)
        if params[:id]  == 'templates'
          redirect_to project_path(@project)
        end
        logger.info("PARAMS:")
        logger.info(params)
        if params[:is_dirty]
          @project.set_is_dirty = true
        end
        logger.info(@project.is_dirty)
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
        # logger.info("COPY EXTENDED:")
        @issue_custom_fields = IssueCustomField.sorted.to_a
        @trackers = Tracker.sorted.to_a
        @source_project = Project.find(params[:id])
        @project = Project.copy_from(@source_project)
        @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
        # logger.info("PARAMS:")
        # logger.info(params)
        if params[:commit]
          Mailer.with_deliveries(params[:notifications] == '1') do
            # logger.info("BEFORE NEW:")
            # @project = Project.new
            project_params = params[:project]
            # project_params[:template_id] = params[:id]
            # logger.info("AFTER NEW:")
            # logger.info(project_params)
            @project.safe_attributes = project_params
            custom_values = @source_project.custom_values.collect {|v| v.clone}
            #logger.info("BEFORE COPY TRY:")
            #logger.info(custom_values)
            #logger.info("BEFORE COPY TRY:")
            if @project.copy(@source_project, :only => params[:only])
              #logger.info("IN NEW:")
              #logger.info(@source_project.custom_values)
              flash[:notice] = l(:notice_successful_create)
              if Project.find(params[:id]).custom_values.collect {|v| v.clone} != custom_values
                #logger.info("RENEW TEMPLATE:")
                custom_values.each do |custom_value|
                  custom_value.customized_id = @source_project.id
                  record = CustomValue.new(
                      #:id => custom_value.id,
                      :customized_type => custom_value.customized_type,
                      :customized_id => @source_project.id,
                      :custom_field_id =>custom_value.custom_field_id,
                      :value =>custom_value.value
                  )
                  record.save
                end
              end
              #logger.info("AFTER COPY TRY:")
              #logger.info(@source_project.custom_values)
              #logger.info(custom_values)
              redirect_to settings_project_path(@project)
            elsif !@project.new_record?
              #logger.info("NOT NEW:")
              #logger.info(Project.find(params[:id]).custom_values.collect {|v| v.clone})
              #logger.info(custom_values)
              if Project.find(params[:id]).custom_values.collect {|v| v.clone} != custom_values
                #logger.info("RENEW TEMPLATE:")
                custom_values.each do |custom_value|
                  custom_value.customized_id = @source_project.id
                  record = CustomValue.new(
                      #:id => custom_value.id,
                      :customized_type => custom_value.customized_type,
                      :customized_id => @source_project.id,
                      :custom_field_id =>custom_value.custom_field_id,
                      :value =>custom_value.value
                  )
                  record.save
                end
              end
              #logger.info("NOT NEW AFTER:")
              #logger.info(Project.find(params[:id]).custom_values.collect {|v| v.clone})
              #logger.info(custom_values)
              # Project was created
              # But some objects were not copied due to validation failures
              # (eg. issues from disabled trackers)
              # flash[:notice] = l(:notice_successful_create)
              # noinspection RubyResolve
              redirect_to settings_project_path(@project)
            end
          end
        end
        if @project && @project.children
          @subprojects = @project.children.visible.to_a
        end
      rescue ActiveRecord::RecordNotFound
        # source_project not found
        render_404
      end

      def update_custom_with_update
        @project.safe_attributes = params[:project]
        @template = nil
        @settings = Setting.plugin_redmine_project_specific_custom_project_fields
        @project.set_is_dirty = false
        if @project.identifier.first(8) != 'template'
          @project.custom_field_values.each do |value|
            if value.custom_field.id == @settings['custom_field_id'].to_i
              @template_id = value.to_s.downcase
              if @template_id.to_s != ''
                @template = Project.find(@template_id)
                is_dirty = false
                if @project.enabled_module_names.sort.to_a != @template.enabled_module_names.sort.to_a
                  @project.enabled_module_names = @template.enabled_module_names
                  is_dirty = true
                end
                if @project.trackers.sort.to_a != @template.trackers.sort.to_a
                  @project.trackers = @template.trackers
                  is_dirty = true
                end

                @project.set_is_dirty = is_dirty

                if @project.is_dirty
                  @project.save
                end
                break
              end
            end
          end
        else
          logger.info("PROJECTS")
          # noinspection RubyResolve
          CustomValue.where(:value => @project.identifier,:customized_type => 'Project').each do |value|
            # noinspection RubyResolve
            @_project = Project.find_by_id(value.customized_id)

            is_dirty = false

            if @_project.enabled_module_names.sort.to_a != @project.enabled_module_names.sort.to_a
              @_project.enabled_module_names = @project.enabled_module_names
              is_dirty = true
            end
            if @_project.trackers.sort.to_a != @project.trackers.sort.to_a
              @_project.trackers = @project.trackers
              is_dirty = true
            end

            @project.set_is_dirty = is_dirty

            if @project.is_dirty
              @project.save
            end
          end
        end

        if @project.is_dirty && @project.identifier.first(8) != 'template'
          # logger.info('ZWISCCHEN 123')
          # logger.info(@project.is_dirty)
          respond_to do |format|
            url = { :controller => 'projects', :id => @project.id, :action => 'settings', :is_dirty => true }
            format.html {
              redirect_to url
            }
            format.api  { render_api_ok }
          end
        else
          if @project.save
            # logger.info('TESTJACCKPOT 123')
            respond_to do |format|
              format.html {
                flash[:notice] = l(:notice_successful_update)
                redirect_to settings_project_path(@project, params[:tab])
              }
              format.api  { render_api_ok }
            end
          else
            if params[:project][:was_dirty]
              # logger.info('OOOOH 123')
              respond_to do |format|
                format.html {
                  flash[:notice] = l(:notice_successful_update_template)
                  settings
                  render :action => 'settings'
                }
                format.api  { render_validation_errors(@project) }
              end
            else
              # logger.info('OOOOH 123')
              respond_to do |format|
                format.html {
                  settings
                  render :action => 'settings'
                }
                format.api  { render_validation_errors(@project) }
              end
            end
          end
        end
      end
      #
      def require_login_custom_with_require_login
        if params[:action] == "copy_template" && params[:controller] == "projects"
          false
        else
          require_login_custom_without_require_login
        end
      end

      # Authorize the user for the requested action
      def authorize_custom_with_authorize(ctrl = params[:controller], action = params[:action], global = false)
        if action == "copy_template" && ctrl == "projects"
          true
        else
          authorize_custom_without_authorize(ctrl, action, global)
        end
      end
    end
  end
end

ProjectsController.send(:include, ProjectSpecificCustomProjectFields::ProjectsControllerPatch)
