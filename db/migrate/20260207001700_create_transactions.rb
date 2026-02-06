class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :title
      t.text :description

      t.references :lender, null: false, foreign_key: { to_table: :users }
      t.references :borrower, null: false, foreign_key: { to_table: :users }
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.integer :lent_money_cents, null: false
      t.integer :outstanding_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
