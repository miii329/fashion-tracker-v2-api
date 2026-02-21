class AddCategoryToBrands < ActiveRecord::Migration[8.1]
  def change
    add_column :brands, :category, :string
  end
end
