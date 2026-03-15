require 'rails_helper'

RSpec.describe BalanceCalculator do
  let(:dewoo) { create(:user, name: "Dewoo") }
  let(:rahul) { create(:user, name: "Rahul") }
  let(:priya) { create(:user, name: "Priya") }
  let(:group) { create(:group, name: "Goa Trip", created_by: dewoo) }

  before do
    group.members << [dewoo, rahul, priya]
  end

  describe "#user_balances" do
    it "calculates net balances correctly" do
      # Dewoo pays 900 for dinner, split equally (300 each)
      expense = create(:expense, group: group, paid_by: dewoo, amount: 900)
      expense.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense.expense_splits.create!(user: rahul, amount_owed: 300)
      expense.expense_splits.create!(user: priya, amount_owed: 300)

      calculator = BalanceCalculator.new(group)
      balances = calculator.user_balances

      # Dewoo paid 900, owes 300 → net +600
      expect(balances[dewoo.id].round(2)).to eq(600.0)
      # Rahul paid 0, owes 300 → net -300
      expect(balances[rahul.id].round(2)).to eq(-300.0)
      # Priya paid 0, owes 300 → net -300
      expect(balances[priya.id].round(2)).to eq(-300.0)
    end

    it "factors in settlements" do
      expense = create(:expense, group: group, paid_by: dewoo, amount: 900)
      expense.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense.expense_splits.create!(user: rahul, amount_owed: 300)
      expense.expense_splits.create!(user: priya, amount_owed: 300)

      # Rahul pays Dewoo 300
      create(:settlement, group: group, payer: rahul, payee: dewoo, amount: 300)

      calculator = BalanceCalculator.new(group)
      balances = calculator.user_balances

      expect(balances[dewoo.id].round(2)).to eq(300.0)   # 600 - 300 received
      expect(balances[rahul.id].round(2)).to eq(0.0)     # -300 + 300 paid
      expect(balances[priya.id].round(2)).to eq(-300.0)   # unchanged
    end
  end

  describe "#calculate (debt simplification)" do
    it "returns simplified transactions" do
      expense = create(:expense, group: group, paid_by: dewoo, amount: 900)
      expense.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense.expense_splits.create!(user: rahul, amount_owed: 300)
      expense.expense_splits.create!(user: priya, amount_owed: 300)

      calculator = BalanceCalculator.new(group)
      transactions = calculator.calculate

      expect(transactions.length).to eq(2)

      # Both Rahul and Priya owe Dewoo 300
      amounts = transactions.map { |t| t[:amount] }
      expect(amounts).to match_array([300.0, 300.0])

      # All payments go TO Dewoo
      payees = transactions.map { |t| t[:to][:id] }
      expect(payees).to all(eq(dewoo.id))
    end

    it "returns empty when all settled" do
      expense = create(:expense, group: group, paid_by: dewoo, amount: 600)
      expense.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense.expense_splits.create!(user: rahul, amount_owed: 300)

      create(:settlement, group: group, payer: rahul, payee: dewoo, amount: 300)

      calculator = BalanceCalculator.new(group)
      transactions = calculator.calculate

      # Only Dewoo and Rahul were involved, and Rahul settled
      # Priya had no expenses
      debts_with_amount = transactions.select { |t| t[:amount] > 0 }
      expect(debts_with_amount).to be_empty
    end

    it "minimizes number of transactions" do
      # Multiple expenses creating complex debts
      expense1 = create(:expense, group: group, paid_by: dewoo, amount: 900)
      expense1.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense1.expense_splits.create!(user: rahul, amount_owed: 300)
      expense1.expense_splits.create!(user: priya, amount_owed: 300)

      expense2 = create(:expense, group: group, paid_by: rahul, amount: 600)
      expense2.expense_splits.create!(user: dewoo, amount_owed: 200)
      expense2.expense_splits.create!(user: rahul, amount_owed: 200)
      expense2.expense_splits.create!(user: priya, amount_owed: 200)

      calculator = BalanceCalculator.new(group)
      transactions = calculator.calculate

      # Should be 2 or fewer transactions (greedy simplification)
      expect(transactions.length).to be <= 2

      # Total flow should be correct
      total = transactions.sum { |t| t[:amount] }
      expect(total.round(2)).to eq(500.0)  # 400 + 100
    end
  end

  describe "balances sum to zero" do
    it "net balances always sum to zero" do
      expense = create(:expense, group: group, paid_by: dewoo, amount: 900)
      expense.expense_splits.create!(user: dewoo, amount_owed: 300)
      expense.expense_splits.create!(user: rahul, amount_owed: 300)
      expense.expense_splits.create!(user: priya, amount_owed: 300)

      calculator = BalanceCalculator.new(group)
      balances = calculator.user_balances
      total = balances.values.sum

      expect(total.round(2)).to eq(0.0)
    end
  end
end
