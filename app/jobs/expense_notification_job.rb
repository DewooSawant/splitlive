class ExpenseNotificationJob < ApplicationJob
  queue_as :default

  def perform(expense_id)
    expense = Expense.find(expense_id)
    group = expense.group

    group.members.each do |member|
      next if member.id == expense.paid_by_id

      ExpenseMailer.expense_added(expense, member).deliver_now
    end
  end
end
