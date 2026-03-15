require 'rails_helper'

RSpec.describe Settlement, type: :model do
  describe "validations" do
    it "is valid with group, payer, payee, and amount" do
      payer = create(:user)
      payee = create(:user)
      group = create(:group)
      settlement = build(:settlement, group: group, payer: payer, payee: payee)
      expect(settlement).to be_valid
    end

    it "is invalid without an amount" do
      settlement = build(:settlement, amount: nil)
      expect(settlement).not_to be_valid
    end

    it "is invalid with zero amount" do
      settlement = build(:settlement, amount: 0)
      expect(settlement).not_to be_valid
    end

    it "is invalid when payer and payee are the same" do
      user = create(:user)
      settlement = build(:settlement, payer: user, payee: user)
      expect(settlement).not_to be_valid
      expect(settlement.errors[:payee]).to include("can't be the same as payer")
    end
  end
end
