require 'rails_helper'

RSpec.describe "Groups API", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /api/v1/groups" do
    it "creates a group and adds creator as member" do
      post "/api/v1/groups", params: { name: "Goa Trip" }, headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Goa Trip")
      expect(json["members"].length).to eq(1)
      expect(json["members"][0]["id"]).to eq(user.id)
    end

    it "rejects group without a name" do
      post "/api/v1/groups", params: { name: "" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/groups" do
    it "returns only groups the user is a member of" do
      group1 = create(:group, created_by: user)
      group1.members << user

      other_user = create(:user)
      group2 = create(:group, created_by: other_user)
      group2.members << other_user

      get "/api/v1/groups", headers: headers

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]["name"]).to eq(group1.name)
    end

    it "returns unauthorized without token" do
      get "/api/v1/groups"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/groups/:id" do
    it "returns group details with members" do
      group = create(:group, created_by: user)
      group.members << user

      get "/api/v1/groups/#{group.id}", headers: headers

      json = JSON.parse(response.body)
      expect(json["name"]).to eq(group.name)
      expect(json["members"]).to be_present
      expect(json["created_by"]["id"]).to eq(user.id)
    end

    it "returns 404 for group user is not a member of" do
      other_group = create(:group)

      get "/api/v1/groups/#{other_group.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
