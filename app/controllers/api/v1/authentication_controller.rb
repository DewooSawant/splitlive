module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_request, only: [ :signup, :login ]

      def signup
        user = User.new(signup_params)

        if user.save
          token = JwtService.encode(user.id)
          render json: { token: token, user: user_response(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: login_params[:email]&.downcase)

        if user&.authenticate(login_params[:password])
          token = JwtService.encode(user.id)
          render json: { token: token, user: user_response(user) }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      private

      def signup_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def login_params
        params.permit(:email, :password)
      end

      def user_response(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
