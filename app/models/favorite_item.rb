class FavoriteItem < ApplicationRecord
  belongs_to :user

  validates :item_name, presence: true
  validates :brand_name, presence: true
  validates :category, presence: true

  # 価格は整数のみ許可
  validates :price, numericality: { only_integer: true, allow_blank: true }

  # URLのフォーマット検証
  validates :url, format: { with: URI::regexp(%w[http https]), allow_blank: true }
end
