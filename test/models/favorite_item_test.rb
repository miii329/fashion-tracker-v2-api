require "test_helper"

class FavoriteItemTest < ActiveSupport::TestCase
  test "can persist image_url" do
    favorite_item = favorite_items(:one)
    image_url = "https://example.com/image.png"
    item_url = "https://example.com/items/1"

    favorite_item.update!(url: item_url, image_url: image_url)

    assert_equal image_url, favorite_item.reload.image_url
  end
end
