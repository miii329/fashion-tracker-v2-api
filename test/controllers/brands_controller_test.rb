require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = brands(:one)
  end

  test "should get index" do
    get brands_url, as: :json
    assert_response :success
  end

  test "should create brand" do
    assert_difference("Brand.count") do
      post brands_url, params: { brand: { description: @brand.description, name: @brand.name, url: @brand.url } }, as: :json
    end

    assert_response :created
  end

  test "should show brand" do
    get brand_url(@brand), as: :json
    assert_response :success
  end

  test "should update brand" do
    patch brand_url(@brand), params: { brand: { description: @brand.description, name: @brand.name, url: @brand.url } }, as: :json
    assert_response :success
  end

  test "should destroy brand" do
    assert_difference("Brand.count", -1) do
      delete brand_url(@brand), as: :json
    end

    assert_response :no_content
  end
end
