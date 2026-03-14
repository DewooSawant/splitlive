class ExpenseSplit < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  validates :amount_owed, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :expense_id, message: "already has a split for this expense" }
end
