class AddUserToBrands < ActiveRecord::Migration[8.1]
  def change
    add_reference :brands, :user, null: true, foreign_key: true

    # 既存データにデフォルトユーザーを設定（最初のユーザー）
    reversible do |dir|
      dir.up do
        if Brand.where(user_id: nil).exists?
          default_user = User.first
          Brand.where(user_id: nil).update_all(user_id: default_user.id) if default_user
        end
        change_column_null :brands, :user_id, false
      end

      dir.down do
        change_column_null :brands, :user_id, true
      end
    end
  end
end
