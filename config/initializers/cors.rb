Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    allowed_origins = [ "http://localhost:3001" ]
    allowed_origins << ENV["FRONTEND_URL"] if ENV["FRONTEND_URL"].present?

    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
