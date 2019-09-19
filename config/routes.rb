# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/:id/project_specific_fields/new', to: 'project_specific_fields#new'
post '/:id/project_specific_fields/create', to: 'project_specific_fields#create'
resources 'project_specific_fields', :only => [ :show, :edit, :update, :destroy]
  

resources :projects do
  resources :project_specific_field_projects
end

resources :project_specific_field_projects do
  collection do
    get 'autocomplete'
    get 'bulk_edit'
    post 'bulk_update'
    get 'context_menu'
  end
end