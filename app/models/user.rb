class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_groups, class_name: "Group", foreign_key: :created_by_id
  has_many :expenses, foreign_key: :paid_by_id
  has_many :expense_splits
  has_many :payments_made, class_name: "Settlement", foreign_key: :payer_id
  has_many :payments_received, class_name: "Settlement", foreign_key: :payee_id

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
