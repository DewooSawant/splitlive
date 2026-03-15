FactoryBot.define do
  factory :settlement do
    amount { 100.00 }
    association :group
    association :payer, factory: :user
    association :payee, factory: :user
  end
end
