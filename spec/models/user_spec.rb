require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with name, email, and password" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "is invalid without a name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "is invalid without an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "is invalid with a duplicate email" do
      create(:user, email: "same@test.com")
      duplicate = build(:user, email: "same@test.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it "is invalid with a duplicate email (case insensitive)" do
      create(:user, email: "Test@Example.com")
      duplicate = build(:user, email: "test@example.com")
      expect(duplicate).not_to be_valid
    end

    it "is invalid with a badly formatted email" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
    end
  end

  describe "email normalization" do
    it "downcases email before saving" do
      user = create(:user, email: "DEWOO@Test.Com")
      expect(user.email).to eq("dewoo@test.com")
    end
  end

  describe "authentication" do
    it "authenticates with correct password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "rejects incorrect password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("wrong")).to be_falsey
    end
  end

  describe "associations" do
    it "has many groups through memberships" do
      user = create(:user)
      group = create(:group)
      group.members << user
      expect(user.groups).to include(group)
    end

    it "has many created_groups" do
      user = create(:user)
      group = create(:group, created_by: user)
      expect(user.created_groups).to include(group)
    end
  end
end
