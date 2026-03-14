module Api
  module V1
    class MembersController < ApplicationController
      before_action :set_group

      def create
        user = User.find_by(email: params[:email])

        unless user
          render json: { error: "User not found with this email" }, status: :not_found
          return
        end

        if @group.members.include?(user)
          render json: { error: "User is already a member of this group" }, status: :unprocessable_entity
          return
        end

        @group.members << user
        render json: { message: "#{user.name} added to #{@group.name}" }, status: :created
      end

      private

      def set_group
        @group = @current_user.groups.find_by(id: params[:group_id])
        render json: { error: "Group not found" }, status: :not_found unless @group
      end
    end
  end
end
