class Group < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :expenses, dependent: :destroy
  has_many :settlements, dependent: :destroy

  validates :name, presence: true
end
