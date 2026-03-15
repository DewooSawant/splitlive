require 'rails_helper'

RSpec.describe Expense, type: :model do
  describe "validations" do
    it "is valid with all required fields" do
      expense = build(:expense)
      expect(expense).to be_valid
    end

    it "is invalid without an amount" do
      expense = build(:expense, amount: nil)
      expect(expense).not_to be_valid
    end

    it "is invalid with zero amount" do
      expense = build(:expense, amount: 0)
      expect(expense).not_to be_valid
    end

    it "is invalid with negative amount" do
      expense = build(:expense, amount: -100)
      expect(expense).not_to be_valid
    end

    it "is invalid without a description" do
      expense = build(:expense, description: nil)
      expect(expense).not_to be_valid
    end
  end

  describe "enum" do
    it "has equal as default split_type" do
      expense = Expense.new
      expect(expense.split_type).to eq("equal")
    end

    it "supports percentage split" do
      expense = build(:expense, split_type: :percentage)
      expect(expense.percentage?).to be true
    end

    it "supports exact split" do
      expense = build(:expense, split_type: :exact)
      expect(expense.exact?).to be true
    end
  end
end
