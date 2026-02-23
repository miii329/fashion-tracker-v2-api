class AddImageUrlToFavoriteItems < ActiveRecord::Migration[8.1]
  def change
    add_column :favorite_items, :image_url, :string
  end
end
