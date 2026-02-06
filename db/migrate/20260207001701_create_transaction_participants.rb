class CreateTransactionParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_participants do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 2

      t.timestamps
    end

    add_index :transaction_participants, [:transaction_id, :user_id], unique: true
  end
end
