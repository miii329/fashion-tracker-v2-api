module Authentication
  extend ActiveSupport::Concern

  included do
    # 1. まず誰かを特定し、Current.userに保存する
    before_action :authenticate_user_from_token
    # 2. 次に、Current.userがいなければ拒否する
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    render json: { error: "認証が必要です" }, status: :unauthorized unless authenticated_user
  end

  def authenticated_user
    @authenticated_user ||= authenticate_user_from_token
  end

  def authenticate_user_from_token
    header = request.headers["Authorization"]
    return nil unless header&.starts_with?("Bearer ")

    token = header.split(" ").last
    payload = JwtService.decode(token)

    # ユーザーを見つけたら Current.user という箱に入れる
    if payload
      Current.user = User.find_by(id: payload["user_id"])
    end
  end

end
