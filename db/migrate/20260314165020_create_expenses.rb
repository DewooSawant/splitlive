class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.references :group, null: false, foreign_key: true
      t.references :paid_by, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :description, null: false
      t.string :category
      t.integer :split_type, null: false, default: 0

      t.timestamps
    end
  end
end
