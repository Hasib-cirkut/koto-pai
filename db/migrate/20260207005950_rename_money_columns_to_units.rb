class RenameMoneyColumnsToUnits < ActiveRecord::Migration[8.0]
  def change
    rename_column :chains, :lent_money_cents, :lent_money
    rename_column :chains, :outstanding_cents, :outstanding
    rename_column :checkpoints, :amount_cents, :amount
  end
end
