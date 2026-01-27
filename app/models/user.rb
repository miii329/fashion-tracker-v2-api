class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :fullname, presence: true

  # 管理者かどうかを判定
  def admin?
    admin
  end
end
