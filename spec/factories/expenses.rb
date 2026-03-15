FactoryBot.define do
  factory :expense do
    description { "Test Expense" }
    amount { 300.00 }
    category { "food" }
    split_type { :equal }
    association :group
    association :paid_by, factory: :user
  end
end
