class AddOgImageUrlToBrands < ActiveRecord::Migration[8.1]
  def change
    add_column :brands, :og_image_url, :string
  end
end
