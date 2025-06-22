Rails.application.routes.draw do
  namespace :admin do
    get "jobs/index"
  end
  # Super Admin routes
  namespace :super_admin do
    get "users/index"
    get "users/show"
    get "users/edit"
    get "users/update"
    get "users/destroy"
    resources :schools do
      member do
        patch :toggle_status
      end
    end

    resources :users, only: [ :index, :show, :edit, :update, :destroy ]
    root "schools#index"
  end
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root route to dashboard
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # School management
  resources :schools do
    resources :terms do
      member do
        get :licenses
      end

      resources :licenses do
        member do
          post :purchase
        end
      end

      # Term enrollment route
      resources :enrollments, only: [ :new, :create ], controller: "enrollments"
    end

    resources :courses, except: [ :destroy ] do
      resources :chapters do
        resources :course_contents, except: [ :index ]
      end

      # Course-specific actions
      member do
        post :enroll
        delete :unenroll
      end

      # Course enrollment route
      resources :enrollments, only: [ :new, :create ], controller: "enrollments"
    end

    # School-specific user management
    resources :users, except: [ :show ] do
      member do
        patch :toggle_status
      end
    end
  end

  # Global course browsing (for students)
  resources :courses, only: [ :index, :show ] do
    member do
      post :enroll
      delete :unenroll
    end
  end

  # Course payments
  resources :schools do
    resources :courses, only: [] do
      resources :payments, only: [ :new, :create ]
    end
  end

  # User profile management
  resource :profile, only: [ :show, :edit, :update ]

  # Enrollments management (unified for both course and term enrollments)
  resources :enrollments, only: [ :index, :show, :destroy ]

  # License Accesses (for students to view their purchased licenses)
  resources :license_accesses, only: [ :index, :show ], path: "my-licenses"

  # Payments (global access)
  resources :payments, only: [ :index, :show ]

  # Licenses (global browsing)
  resources :licenses, only: [ :index, :show ]

  # License renewals
  resources :license_renewals, only: [ :index, :show ] do
    member do
      post :renew
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Solid Queue Dashboard
  mount SolidQueueDashboard::Engine, at: "/solid-queue"


  # Solid Cache Dashboard
  mount SolidCache::Engine => "/solid_cache"
end
