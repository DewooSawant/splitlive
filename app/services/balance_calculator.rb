class BalanceCalculator
  def initialize(group)
    @group = group
  end

  def calculate
    net_balances = calculate_net_balances
    simplify_debts(net_balances)
  end

  def user_balances
    calculate_net_balances
  end

  private

  # Step A: Calculate how much each person paid vs how much they owe
  def calculate_net_balances
    balances = Hash.new(0.0)

    # Add what each person PAID
    @group.expenses.each do |expense|
      balances[expense.paid_by_id] += expense.amount.to_f
    end

    # Subtract what each person OWES (their share of each expense)
    @group.expenses.includes(:expense_splits).each do |expense|
      expense.expense_splits.each do |split|
        balances[split.user_id] -= split.amount_owed.to_f
      end
    end

    # Step B: Factor in settlements
    @group.settlements.each do |settlement|
      balances[settlement.payer_id] += settlement.amount.to_f
      balances[settlement.payee_id] -= settlement.amount.to_f
    end

    balances
  end

  # Step C: Greedy algorithm to minimize transactions
  def simplify_debts(net_balances)
    # Separate into creditors (positive balance) and debtors (negative balance)
    creditors = []
    debtors = []

    members = @group.members.index_by(&:id)

    net_balances.each do |user_id, balance|
      rounded = balance.round(2)
      next if rounded.zero?

      if rounded > 0
        creditors << { user_id: user_id, name: members[user_id]&.name, amount: rounded }
      else
        debtors << { user_id: user_id, name: members[user_id]&.name, amount: rounded.abs }
      end
    end

    # Sort both by amount descending (biggest first)
    creditors.sort_by! { |c| -c[:amount] }
    debtors.sort_by! { |d| -d[:amount] }

    # Match debtors to creditors greedily
    transactions = []

    while creditors.any? && debtors.any?
      creditor = creditors.first
      debtor = debtors.first

      # The transfer amount is the minimum of what's owed and what's due
      transfer = [creditor[:amount], debtor[:amount]].min.round(2)

      transactions << {
        from: { id: debtor[:user_id], name: debtor[:name] },
        to: { id: creditor[:user_id], name: creditor[:name] },
        amount: transfer
      }

      creditor[:amount] = (creditor[:amount] - transfer).round(2)
      debtor[:amount] = (debtor[:amount] - transfer).round(2)

      # Remove if fully settled
      creditors.shift if creditor[:amount].zero?
      debtors.shift if debtor[:amount].zero?
    end

    transactions
  end
end
