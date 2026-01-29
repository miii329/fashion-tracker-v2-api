require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.create!(email_address: "test@example.com", password: "password", password_confirmation: "password", fullname: "Test User") }

  test "create with valid credentials" do
    post api_v2_session_path, params: { email_address: @user.email_address, password: "password" }, as: :json

    assert_response :ok
    assert_equal "ログインしました", JSON.parse(response.body)["message"]
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post api_v2_session_path, params: { email_address: @user.email_address, password: "wrong" }, as: :json

    assert_response :unauthorized
    assert_equal "メールアドレスまたはパスワードが正しくありません", JSON.parse(response.body)["error"]
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete api_v2_session_path, as: :json

    assert_response :ok
    assert_equal "ログアウトしました", JSON.parse(response.body)["message"]
  end
end
