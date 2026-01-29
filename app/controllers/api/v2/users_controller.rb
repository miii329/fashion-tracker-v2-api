class Api::V2::UsersController < ApplicationController
    allow_unauthenticated_access only: :create

    def create
    @user = User.new(user_params)
    if @user.save
      # 登録成功：JSONでユーザー情報を返す
      render json: { message: "ユーザー登録が完了しました", user: @user }, status: :created
    else
      # 失敗：バリデーションエラーなどをJSONで返す
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :fullname)
  end
end
