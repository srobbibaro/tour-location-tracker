Rails.application.routes.draw do
  # Authentication
  devise_for :users, :skip => [:passwords, :registrations]
    as :user do
      namespace :user do
        patch 'update'
        get 'edit'
      end
      scope '/admin' do
        resources :user, :controller => 'user_admin'
        get 'impersonate_user', :controller => 'user_admin'
        post 'halt_impersonate_user', :controller => 'user_admin'
      end
    end

  # Pages
  get 'tour_locations/index'

  # Pages API
  post 'tour_locations/locations'
  post 'tour_locations/add_location'
  post 'tour_locations/remove_location'
  post 'location_check/find_location'

  # Site root
  root 'tour_locations#index'
end
