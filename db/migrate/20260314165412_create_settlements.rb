class CreateSettlements < ActiveRecord::Migration[7.2]
  def change
    create_table :settlements do |t|
      t.references :group, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.references :payee, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, null: false, precision: 10, scale: 2

      t.timestamps
    end
  end
end
