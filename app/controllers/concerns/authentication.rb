module Authentication
  extend ActiveSupport::Concern

  included do
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
    header = request.headers['Authorization']
    return nil unless header&.starts_with?('Bearer ')

    token = header.split(' ').last
    payload = JwtService.decode(token)
    return nil unless payload

    User.find_by(id: payload['user_id'])
  end

  def Current.user
    @current_user ||= authenticated_user
  end

  def request_authentication
    render json: { error: "認証が必要です" }, status: :unauthorized
  end
end
