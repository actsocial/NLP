Mltraining::Application.routes.draw do

  get "topic_dates/chart"
  post "topic_dates/get_daily_topics"
  resources :topic_dates

  get "posts/get_features"
  get "tags/test"

  post "calc/rebuild"
  post "calc/test_rebuild"

  post "posts/change_tag"
  post "posts/confirm_import"
  post "posts/import_data"
  post "posts/select_tag"
  post "posts/do_feature"
  post "posts/change"


  post "tags/load_data"
  post "tags/save_to_redis"
  post "tags/add_to_redis"
  post "tags/show"
  post "tags/sync"
  post "tags/runtest"

  get "posts/chart"
  post "posts/get_daily_posts"

  get "topicshow/detect_show2"
  get "topicshow/detect_show"
  get "topicshow/topic_svg_show"
  get "topicshow/flare_imports"
  get "topicshow/get_word_to_word_relation"
  get "topicshow/get_word_in_arr_relation"
  get "topicshow/get_json"

  resources :fnfps
  resources :tags
  resources :priors
  resources :posts

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  root :to => "tags#index"
end
