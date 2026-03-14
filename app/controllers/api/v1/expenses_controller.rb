module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_group

      def index
        expenses = @group.expenses.includes(:paid_by, :expense_splits)
                        .order(created_at: :desc)

        render json: expenses.map { |expense| expense_response(expense) }
      end

      def create
        expense = @group.expenses.new(expense_params)
        expense.paid_by = @current_user

        unless expense.valid?
          render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
          return
        end

        splits = build_splits(expense)
        unless splits
          return
        end

        ActiveRecord::Base.transaction do
          expense.save!
          splits.each { |split| split.save! }
        end

        render json: expense_response(expense), status: :created
      end

      private

      def set_group
        @group = @current_user.groups.find_by(id: params[:group_id])
        render json: { error: "Group not found" }, status: :not_found unless @group
      end

      def expense_params
        params.permit(:amount, :description, :category, :split_type)
      end

      def build_splits(expense)
        case expense.split_type
        when "equal"
          build_equal_splits(expense)
        when "percentage"
          build_percentage_splits(expense)
        when "exact"
          build_exact_splits(expense)
        end
      end

      def build_equal_splits(expense)
        members = @group.members
        share = (expense.amount / members.count).round(2)
        remainder = expense.amount - (share * members.count)

        members.map.with_index do |member, index|
          amount = index == 0 ? share + remainder : share
          expense.expense_splits.new(user: member, amount_owed: amount)
        end
      end

      def build_percentage_splits(expense)
        split_data = params[:splits]

        unless split_data.present?
          render json: { error: "splits required for percentage split" }, status: :unprocessable_entity
          return nil
        end

        total_percentage = split_data.sum { |s| s[:percentage].to_f }
        unless total_percentage == 100
          render json: { error: "Percentages must add up to 100 (got #{total_percentage})" }, status: :unprocessable_entity
          return nil
        end

        split_data.map do |split|
          user = User.find(split[:user_id])
          amount = (expense.amount * split[:percentage].to_f / 100).round(2)
          expense.expense_splits.new(user: user, amount_owed: amount)
        end
      end

      def build_exact_splits(expense)
        split_data = params[:splits]

        unless split_data.present?
          render json: { error: "splits required for exact split" }, status: :unprocessable_entity
          return nil
        end

        total = split_data.sum { |s| s[:amount].to_f }
        unless total == expense.amount.to_f
          render json: { error: "Split amounts (#{total}) must equal expense amount (#{expense.amount})" }, status: :unprocessable_entity
          return nil
        end

        split_data.map do |split|
          user = User.find(split[:user_id])
          expense.expense_splits.new(user: user, amount_owed: split[:amount].to_f)
        end
      end

      def expense_response(expense)
        {
          id: expense.id,
          description: expense.description,
          amount: expense.amount.to_f,
          category: expense.category,
          split_type: expense.split_type,
          paid_by: { id: expense.paid_by.id, name: expense.paid_by.name },
          splits: expense.expense_splits.map do |split|
            { user_id: split.user_id, name: split.user.name, amount_owed: split.amount_owed.to_f }
          end,
          created_at: expense.created_at
        }
      end
    end
  end
end
