require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "POST /api/v1/auth/signup" do
    it "creates a user and returns a token" do
      post "/api/v1/auth/signup", params: {
        name: "Dewoo", email: "dewoo@test.com", password: "password123"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["name"]).to eq("Dewoo")
      expect(json["user"]["email"]).to eq("dewoo@test.com")
    end

    it "returns errors for invalid signup" do
      post "/api/v1/auth/signup", params: { name: "", email: "", password: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "rejects duplicate email" do
      create(:user, email: "taken@test.com")
      post "/api/v1/auth/signup", params: {
        name: "New", email: "taken@test.com", password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "dewoo@test.com", password: "secret123") }

    it "returns a token for valid credentials" do
      post "/api/v1/auth/login", params: { email: "dewoo@test.com", password: "secret123" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("dewoo@test.com")
    end

    it "rejects invalid password" do
      post "/api/v1/auth/login", params: { email: "dewoo@test.com", password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Invalid email or password")
    end

    it "rejects non-existent email" do
      post "/api/v1/auth/login", params: { email: "nobody@test.com", password: "secret123" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
