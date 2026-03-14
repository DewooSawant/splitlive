class Expense < ApplicationRecord
  belongs_to :group
  belongs_to :paid_by, class_name: "User"

  has_many :expense_splits, dependent: :destroy

  enum :split_type, { equal: 0, percentage: 1, exact: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :split_type, presence: true
end
