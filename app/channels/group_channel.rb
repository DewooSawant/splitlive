class GroupChannel < ApplicationCable::Channel
  def subscribed
    group = current_user.groups.find_by(id: params[:group_id])

    if group
      stream_from "group_#{group.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
