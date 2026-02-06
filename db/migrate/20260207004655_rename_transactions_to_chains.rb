class RenameTransactionsToChains < ActiveRecord::Migration[8.0]
  def change
    rename_table :transactions, :chains
    rename_table :transaction_participants, :chain_participants

    rename_column :chain_participants, :transaction_id, :chain_id
    rename_column :checkpoints, :transaction_id, :chain_id

    remove_foreign_key :chain_participants, :transactions if foreign_key_exists?(:chain_participants, :transactions)
    remove_foreign_key :checkpoints, :transactions if foreign_key_exists?(:checkpoints, :transactions)

    add_foreign_key :chain_participants, :chains unless foreign_key_exists?(:chain_participants, :chains)
    add_foreign_key :checkpoints, :chains unless foreign_key_exists?(:checkpoints, :chains)

    remove_index :chain_participants, name: "index_transaction_participants_on_transaction_id" if index_exists?(:chain_participants, :chain_id, name: "index_transaction_participants_on_transaction_id")
    remove_index :chain_participants, name: "index_transaction_participants_on_transaction_id_and_user_id" if index_exists?(:chain_participants, [:chain_id, :user_id], name: "index_transaction_participants_on_transaction_id_and_user_id")
    add_index :chain_participants, [:chain_id, :user_id], unique: true unless index_exists?(:chain_participants, [:chain_id, :user_id], unique: true)
    add_index :chain_participants, :chain_id unless index_exists?(:chain_participants, :chain_id)
  end
end
