Rails.application.routes.draw do
  namespace :api do
    namespace :v2 do
      # ログイン・ログアウト
      resource :session, only: [ :create, :destroy ]
      # ユーザー登録
      resource :users, only: [ :create ] # これが「ユーザー登録」の宛先
      # パスワードリセット
      resources :passwords, param: :token, only: [ :create, :update ]
      # ブランド管理
      resources :brands
      # お気に入りアイテム管理
      resources :favorite_items
      # アイテム一覧・詳細
      resources :items, only: [ :index, :show ]
    end

    # 旧エンドポイントとの互換性（フロントエンド移行期間用）
    namespace :auth do
      delete "logout", to: "v2/sessions#destroy"
      post "login", to: "v2/sessions#create"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
