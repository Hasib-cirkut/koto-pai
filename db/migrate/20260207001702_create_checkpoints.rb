class CreateCheckpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :checkpoints do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.text :note

      t.timestamps
    end
  end
end
