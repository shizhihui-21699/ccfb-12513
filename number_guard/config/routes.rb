Rails.application.routes.draw do
  root "home#index"

  get  "/login",          to: "sessions#new",       as: :login
  post "/login/sms_code", to: "sessions#send_code", as: :login_sms_code
  post "/login",          to: "sessions#create"
  delete "/logout",       to: "sessions#destroy",   as: :logout
  post "/account/confirm_phone", to: "home#confirm_phone", as: :confirm_phone

  resources :verifications, only: [:show] do
    member do
      post :start_email_code
      post :verify_email_code
      post :verify_security_question
      post :submit_manual_review
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :login_attempts, only: [:index, :show]
    resources :verifications, only: [:index, :show] do
      member do
        post :approve
        post :reject
      end
    end
    resources :users, only: [:index, :show]
    resources :carrier_records, except: [:show]
  end
end
