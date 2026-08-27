Rails.application.routes.draw do
  # ========== API (Backend pour mobile/frontend) ==========
  namespace :api do
    namespace :v1 do
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"

      get "profile", to: "users#show"
      patch "profile", to: "users#update"
      patch "profile/location", to: "users#update_location"

      get "cooks/nearby", to: "users#cooks_nearby"
      get "cooks/drivers/list", to: "cooks#drivers"
      post "cooks/drivers/add", to: "cooks#add_driver"
      delete "cooks/drivers/:id", to: "cooks#remove_driver"
      get "cooks/:id", to: "users#cook_profile"
      get "drivers/nearby", to: "users#delivery_drivers_nearby"

      get "menus/search", to: "menus#search"

      resources :meals, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :available_by_day
        end
        resources :reviews, only: [:index, :create]
      end

      resources :daily_products, only: [:index, :show, :create, :update, :destroy]

      resources :orders, only: [:index, :show, :create] do
        member do
          post :accept
          post :complete
          post :assign_driver
          post :accept_delivery
          post :confirm_reception
          post :cancel
          post :mark_delivered
        end
        collection do
          get :my_deliveries
          get :available_for_delivery
        end
      end

      post "orders/:order_id/payments", to: "payments#create", as: :order_payments
      get "payments/history", to: "payments#history"
      get "payments/balance", to: "payments#balance"
      post "payments/withdrawal", to: "payments#withdrawal"

      get "withdrawals", to: "withdrawals#index"
      post "withdrawals/:id/validate", to: "withdrawals#validate"
    end
  end

  # ========== Web (Interface navigateur) ==========
  # Auth
  get "login", to: "web/sessions#new"
  post "login", to: "web/sessions#create"
  get "logout", to: "web/sessions#destroy"
  get "signup", to: "web/users#new"
  post "signup", to: "web/users#create"

  # Dashboard
  get "dashboard", to: "web/dashboard#index"
  root "web/clients#search"

  # Meals (cook)
  get "meals", to: "web/meals#index"
  get "meals/new", to: "web/meals#new"
  post "meals", to: "web/meals#create"
  get "meals/:id/edit", to: "web/meals#edit"
  patch "meals/:id", to: "web/meals#update"
  get "meals/:id/delete", to: "web/meals#destroy"

  # Daily Products (cook)
  get "daily_products", to: "web/daily_products#index"
  get "daily_products/new", to: "web/daily_products#new"
  post "daily_products", to: "web/daily_products#create"
  get "daily_products/:id/delete", to: "web/daily_products#destroy"

  # Orders
  get "orders", to: "web/orders#index"
  get "orders/:id", to: "web/orders#show"
  get "orders/:id/accept", to: "web/orders#accept"
  get "orders/:id/assign", to: "web/orders#assign"
  post "orders/:id/assign_driver", to: "web/orders#assign_driver"
  get "orders/:id/mark_delivered", to: "web/orders#mark_delivered"
  get "orders/:id/accept_delivery", to: "web/orders#accept_delivery"
  get "orders/:id/complete", to: "web/orders#complete"
  get "orders/:id/confirm_reception", to: "web/orders#confirm_reception"
  get "orders/:id/cancel", to: "web/orders#cancel"

  # Payments
  get "orders/:order_id/payments/new", to: "web/payments#new"
  post "orders/:order_id/payments", to: "web/payments#create"
  get "payments/balance", to: "web/payments#balance"
  post "payments/withdrawal", to: "web/payments#withdrawal"
  get "withdrawals", to: "web/payments#withdrawals"

  # Menu search (client)
  get "menus/search", to: "web/clients#search"
  get "cooks/:id", to: "web/cooks#show"
  get "clients/:cook_id/order/:item_type/:item_id", to: "web/clients#order"
  post "clients/:cook_id/order", to: "web/clients#create_order"

  # Deliveries (driver)
  get "deliveries", to: "web/deliveries#index"
  get "deliveries/:id/take", to: "web/deliveries#take"

  # Drivers management (cook)
  get "drivers", to: "web/drivers#index"
  get "drivers/new", to: "web/drivers#new"
  post "drivers", to: "web/drivers#create"
  get "drivers/:id/remove", to: "web/drivers#destroy"

  # Admin
  get "admin", to: "web/admin#index"
  get "admin/withdrawals", to: "web/admin#withdrawals"
  get "admin/withdrawals/:id/validate", to: "web/admin#validate_withdrawal"
end
