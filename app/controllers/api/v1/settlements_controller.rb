module Api
  module V1
    class SettlementsController < ApplicationController
      before_action :set_group

      def index
        settlements = @group.settlements.includes(:payer, :payee)
                           .order(created_at: :desc)

        render json: settlements.map { |s| settlement_response(s) }
      end

      def create
        settlement = @group.settlements.new(settlement_params)
        settlement.payer = @current_user

        if settlement.save
          render json: settlement_response(settlement), status: :created
        else
          render json: { errors: settlement.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_group
        @group = @current_user.groups.find_by(id: params[:group_id])
        render json: { error: "Group not found" }, status: :not_found unless @group
      end

      def settlement_params
        params.permit(:payee_id, :amount)
      end

      def settlement_response(settlement)
        {
          id: settlement.id,
          payer: { id: settlement.payer.id, name: settlement.payer.name },
          payee: { id: settlement.payee.id, name: settlement.payee.name },
          amount: settlement.amount.to_f,
          created_at: settlement.created_at
        }
      end
    end
  end
end
