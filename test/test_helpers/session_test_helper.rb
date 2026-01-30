module SessionTestHelper
  def sign_in_as(user)
    token = JwtService.generate_token_for(user)
    @request.headers["Authorization"] = "Bearer #{token}" if @request
  end

  def sign_out
    # JWTはステートレスなので、クライアント側でトークンを削除する必要がある
    # テストでは特に何もしない
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
