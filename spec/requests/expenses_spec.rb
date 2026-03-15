require 'rails_helper'

RSpec.describe "Expenses API", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) { create(:group, created_by: user) }
  let(:headers) { auth_headers(user) }

  before do
    group.members << user
    group.members << user2
  end

  describe "POST /api/v1/groups/:group_id/expenses" do
    it "creates an expense with equal split" do
      post "/api/v1/groups/#{group.id}/expenses", params: {
        description: "Dinner", amount: 600, category: "food", split_type: "equal"
      }, headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["description"]).to eq("Dinner")
      expect(json["amount"]).to eq(600.0)
      expect(json["splits"].length).to eq(2)
      expect(json["splits"][0]["amount_owed"]).to eq(300.0)
      expect(json["splits"][1]["amount_owed"]).to eq(300.0)
    end

    it "rejects expense without description" do
      post "/api/v1/groups/#{group.id}/expenses", params: {
        amount: 100, split_type: "equal"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects expense with zero amount" do
      post "/api/v1/groups/#{group.id}/expenses", params: {
        description: "Free", amount: 0, split_type: "equal"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/groups/:group_id/expenses" do
    it "returns all expenses for the group" do
      create(:expense, group: group, paid_by: user, description: "Dinner")
      create(:expense, group: group, paid_by: user2, description: "Taxi")

      get "/api/v1/groups/#{group.id}/expenses", headers: headers

      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end
  end
end
