class ProjectSpecificFieldProjectsController < ApplicationController

  menu_item :project_specific_field_projects

  before_action :authorize_global
  before_action :find_project_specific_field_project, only: [:show, :edit, :update]
  before_action :find_project_specific_field_projects, only: [:context_menu, :bulk_edit, :bulk_update, :destroy]
  before_action :find_project

  helper :project_specific_field_projects
  helper :custom_fields
  helper :context_menus
  helper :attachments
  helper :projects

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    
    retrieve_query(ProjectSpecificFieldProjectQuery)
    @entity_count = @query.project_specific_field_projects.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.project_specific_field_projects(offset: @entity_pages.offset, limit: @entity_pages.per_page)
    
  end

  def show
    respond_to do |format|
      format.html
      format.api
      format.js
    end
  end

  def new
    @project_specific_field_project = ProjectSpecificFieldProject.new
    @project_specific_field_project.project = @project
    @project_specific_field_project.safe_attributes = params[:project_specific_field_project]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @project_specific_field_project = ProjectSpecificFieldProject.new author: User.current
    @project_specific_field_project.project = @project
    @project_specific_field_project.safe_attributes = params[:project_specific_field_project]
    @project_specific_field_project.save_attachments(params[:attachments] || (params[:project_specific_field_project] && params[:project_specific_field_project][:uploads]))

    respond_to do |format|
      if @project_specific_field_project.save
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default project_specific_field_project_path(@project_specific_field_project)
        end
        format.api { render action: 'show', status: :created, location: project_specific_field_project_url(@project_specific_field_project) }
        format.js { render template: 'common/close_modal' }
      else
        format.html { render action: 'new' }
        format.api { render_validation_errors(@project_specific_field_project) }
        format.js { render action: 'new' }
      end
    end
  end

  def edit
    @project_specific_field_project.safe_attributes = params[:project_specific_field_project]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @project_specific_field_project.safe_attributes = params[:project_specific_field_project]
    @project_specific_field_project.save_attachments(params[:attachments] || (params[:project_specific_field_project] && params[:project_specific_field_project][:uploads]))

    respond_to do |format|
      if @project_specific_field_project.save
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default project_specific_field_project_path(@project_specific_field_project)
        end
        format.api { render_api_ok }
        format.js { render template: 'common/close_modal' }
      else
        format.html { render action: 'edit' }
        format.api { render_validation_errors(@project_specific_field_project) }
        format.js { render action: 'edit' }
      end
    end
  end

  def destroy
    @project_specific_field_projects.each(&:destroy)

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default project_specific_field_projects_path
      end
      format.api { render_api_ok }
    end
  end

  def bulk_edit
  end

  def bulk_update
    unsaved, saved = [], []
    attributes = parse_params_for_bulk_update(params[:project_specific_field_project])
    @project_specific_field_projects.each do |entity|
      entity.init_journal(User.current) if entity.respond_to? :init_journal
      entity.safe_attributes = attributes
      if entity.save
        saved << entity
      else
        unsaved << entity
      end
    end
    respond_to do |format|
      format.html do
        if unsaved.blank?
          flash[:notice] = l(:notice_successful_update)
        else
          flash[:error] = unsaved.map{|i| i.errors.full_messages}.flatten.uniq.join(",\n")
        end
        redirect_back_or_default :index
      end
    end
  end

  def context_menu
    if @project_specific_field_projects.size == 1
      @project_specific_field_project = @project_specific_field_projects.first
    end

    can_edit = @project_specific_field_projects.detect{|c| !c.editable?}.nil?
    can_delete = @project_specific_field_projects.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url

    @project_specific_field_project_ids, @safe_attributes, @selected = [], [], {}
    @project_specific_field_projects.each do |e|
      @project_specific_field_project_ids << e.id
      @safe_attributes.concat e.safe_attribute_names
      attributes = e.safe_attribute_names - (%w(custom_field_values custom_fields))
      attributes.each do |c|
        column_name = c.to_sym
        if @selected.key? column_name
          @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
        else
          @selected[column_name] = e.send(column_name)
        end
      end
    end

    @safe_attributes.uniq!

    render layout: false
  end

  def autocomplete
  end

  private

  def find_project_specific_field_project
    @project_specific_field_project = ProjectSpecificFieldProject.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project_specific_field_projects
    @project_specific_field_projects = ProjectSpecificFieldProject.visible.where(id: (params[:id] || params[:ids])).to_a
    @project_specific_field_project = @project_specific_field_projects.first if @project_specific_field_projects.count == 1
    raise ActiveRecord::RecordNotFound if @project_specific_field_projects.empty?
    raise Unauthorized unless @project_specific_field_projects.all?(&:visible?)
    @projects = @project_specific_field_projects.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project ||= @project_specific_field_project.project if @project_specific_field_project
    @project ||= Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
