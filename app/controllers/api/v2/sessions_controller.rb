module Api
  module V2
    class SessionsController < ApplicationController
      skip_before_action :require_authentication, only: [ :create, :destroy ]
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "Try again later." }, status: :too_many_requests }

      def create
        if user = User.authenticate_by(params.permit(:email_address, :password))
          token = JwtService.generate_token_for(user)
          render json: {
            message: "ログインしました",
            user: user,
            authToken: token,
            tokenType: "Bearer"
          }, status: :ok
        else
          render json: { error: "メールアドレスまたはパスワードが正しくありません" }, status: :unauthorized
        end
      end

      def destroy
        # JWTはステートレスなので、クライアント側でトークンを削除する必要がある
        render json: { message: "ログアウトしました" }, status: :ok
      end
    end
  end
end
