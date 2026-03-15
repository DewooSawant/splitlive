class ExpenseMailer < ApplicationMailer
  def expense_added(expense, recipient)
    @expense = expense
    @recipient = recipient
    @group = expense.group
    @paid_by = expense.paid_by
    @split = expense.expense_splits.find_by(user: recipient)

    mail(
      to: recipient.email,
      subject: "New expense in #{@group.name}: #{@expense.description} - ₹#{@expense.amount}"
    )
  end
end
