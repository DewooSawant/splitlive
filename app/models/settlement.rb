class Settlement < ApplicationRecord
  belongs_to :group
  belongs_to :payer, class_name: "User"
  belongs_to :payee, class_name: "User"

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :payer_and_payee_are_different

  private

  def payer_and_payee_are_different
    if payer_id == payee_id
      errors.add(:payee, "can't be the same as payer")
    end
  end
end
