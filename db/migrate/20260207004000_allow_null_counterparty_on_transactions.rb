class AllowNullCounterpartyOnTransactions < ActiveRecord::Migration[8.0]
  def change
    change_column_null :transactions, :lender_id, true
    change_column_null :transactions, :borrower_id, true
  end
end
