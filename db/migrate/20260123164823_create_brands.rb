class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name
      t.string :url
      t.text :description

      t.timestamps
    end
  end
end
