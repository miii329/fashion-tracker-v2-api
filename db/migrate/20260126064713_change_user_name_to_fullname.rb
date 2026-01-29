class ChangeUserNameToFullname < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :first_name, :string
    remove_column :users, :last_name, :string
    add_column :users, :fullname, :string
  end
end
