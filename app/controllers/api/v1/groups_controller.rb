module Api
  module V1
    class GroupsController < ApplicationController
      before_action :set_group, only: [:show, :balances]

      def index
        groups = @current_user.groups
        render json: groups.map { |group| group_response(group) }
      end

      def show
        render json: group_detail_response(@group)
      end

      def balances
        calculator = BalanceCalculator.new(@group)
        render json: {
          user_balances: calculator.user_balances.map { |user_id, balance|
            member = @group.members.find { |m| m.id == user_id }
            { user: { id: user_id, name: member&.name }, balance: balance.round(2) }
          },
          simplified_debts: calculator.calculate
        }
      end

      def create
        group = @current_user.created_groups.new(group_params)

        if group.save
          group.members << @current_user
          render json: group_detail_response(group), status: :created
        else
          render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_group
        group_id = params[:group_id] || params[:id]
        @group = @current_user.groups.find_by(id: group_id)
        render json: { error: "Group not found" }, status: :not_found unless @group
      end

      def group_params
        params.permit(:name)
      end

      def group_response(group)
        {
          id: group.id,
          name: group.name,
          members_count: group.members.count,
          created_at: group.created_at
        }
      end

      def group_detail_response(group)
        {
          id: group.id,
          name: group.name,
          created_by: { id: group.created_by.id, name: group.created_by.name },
          members: group.members.map { |m| { id: m.id, name: m.name, email: m.email } },
          created_at: group.created_at
        }
      end
    end
  end
end
