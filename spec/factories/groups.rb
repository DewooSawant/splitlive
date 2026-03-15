FactoryBot.define do
  factory :group do
    name { "Test Group" }
    association :created_by, factory: :user
  end
end
