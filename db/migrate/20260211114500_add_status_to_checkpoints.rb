class AddStatusToCheckpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :checkpoints, :status, :integer, default: 0, null: false
    add_column :checkpoints, :approved_by_id, :bigint
    add_column :checkpoints, :approved_at, :datetime

    add_index :checkpoints, :status
    add_foreign_key :checkpoints, :users, column: :approved_by_id
  end
end
