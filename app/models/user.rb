class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :favorite_items, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :fullname, presence: true

  # 管理者かどうかを判定
  def admin?
    admin
  end

  # JWTトークンを生成
  def generate_jwt_token
    JwtService.generate_token_for(self)
  end
end
