require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.create!(email_address: "test@example.com", password: "password", password_confirmation: "password", fullname: "Test User") }

  test "create with valid credentials" do
    post api_v2_session_path, params: { email_address: @user.email_address, password: "password" }, as: :json

    assert_response :ok
    assert_equal "ログインしました", JSON.parse(response.body)["message"]
    assert JSON.parse(response.body)["authToken"]
    assert_equal "Bearer", JSON.parse(response.body)["tokenType"]
  end

  test "create with invalid credentials" do
    post api_v2_session_path, params: { email_address: @user.email_address, password: "wrong" }, as: :json

    assert_response :unauthorized
    assert_equal "メールアドレスまたはパスワードが正しくありません", JSON.parse(response.body)["error"]
    response_json = JSON.parse(response.body)
    refute response_json["authToken"]
  end

  test "destroy" do
    token = JwtService.generate_token_for(@user)
    delete api_v2_session_path, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :ok
    assert_equal "ログアウトしました", JSON.parse(response.body)["message"]
  end
end
