class ProjectSpecificFieldsController < ApplicationController
  unloadable

  before_action :find_field, :except => [:new, :create]
  before_action :find_project, :only => [:new, :create]
  before_action :authorize
  before_action :build_field_from_params, :only => [:new, :create]
  
  helper 'custom_fields'

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    if @custom_field.save
      redirect_to_index
      return
    end
    render :action => :new
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @custom_field.update_attributes(params.permit(:project_custom_field => [
        :max_length,
        :min_length,
        :regexp,
        :text_formatting,
        :default_value,
        :url_pattern,
        :searchable,
        :field_format,
        :extensions_allowed,
        :multiple,
        :edit_tag_style,
        :name,
        :description,
        :is_required,
        :is_filter,
        :possible_values,
        :role_ids => [],
        :tracker_ids => []
    ]).require(:project_custom_field))
    if @custom_field.save
      redirect_to_index
      return
    end
    render :action => :edit
  end

  def destroy
    @custom_field.destroy
    redirect_to_index    
  end
  
  private
  def find_field
    id = params[:id]
    @custom_field = ProjectCustomField.where(:id => id).first unless id.nil?
    return render_404 if @custom_field.nil?
    @project = self.find_project_by_project_id
    render_404 if @project.nil?
  end
  
  def find_project(project_id=nil)
    project_id ||= id
    @project = Project.find(project_id)
  end
  
  def authorize
    deny_access unless User.current.allowed_to?({:controller => :project_specific_fields, :action => params[:action]}, @project, :global => false)
  end
  
  def build_field_from_params
    @custom_field = ProjectCustomField.new(params.permit(:project_custom_field => [
        :max_length,
        :min_length,
        :regexp,
        :text_formatting,
        :default_value,
        :url_pattern,
        :searchable,
        :field_format,
        :extensions_allowed,
        :multiple,
        :edit_tag_style,
        :name,
        :description,
        :is_required,
        :is_filter,
        :possible_values,
        :role_ids => [],
        :tracker_ids => [],
        :project => nil
    ]).fetch(:project_custom_field, {}))
    if params[:project_custom_field]
      @custom_field.share_with_subprojects = params[:project_custom_field][:share_with_subprojects] # force the update to be manual
    end
    @custom_field.project = @project
  end
  
  def redirect_to_index
    redirect_to :controller => :projects, :action => :settings, :id => @project.identifier, :tab => :custom_fields
  end
end
