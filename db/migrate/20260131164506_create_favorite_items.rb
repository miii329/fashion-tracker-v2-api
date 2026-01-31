class CreateFavoriteItems < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_name
      t.string :brand_name
      t.string :category
      t.integer :price
      t.text :memo
      t.string :url

      t.timestamps
    end
  end
end
