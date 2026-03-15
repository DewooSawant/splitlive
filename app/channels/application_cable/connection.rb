module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      decoded = JwtService.decode(token)

      if decoded
        User.find_by(id: decoded[:user_id]) || reject_unauthorized_connection
      else
        reject_unauthorized_connection
      end
    end
  end
end
