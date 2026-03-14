class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(user_id)
    payload = {
      user_id: user_id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY).first
    decoded.symbolize_keys
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
