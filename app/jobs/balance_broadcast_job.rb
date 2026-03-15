class BalanceBroadcastJob < ApplicationJob
  queue_as :default

  def perform(group_id, event_type, event_data)
    group = Group.find(group_id)
    calculator = BalanceCalculator.new(group)

    ActionCable.server.broadcast("group_#{group_id}", {
      type: event_type,
      data: event_data,
      balances: calculator.calculate
    })
  end
end
