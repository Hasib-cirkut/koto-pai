class ChangeCurrencyDefaultOnTransactions < ActiveRecord::Migration[8.0]
  def change
    change_column_default :transactions, :currency, from: "USD", to: "BDT"
  end
end
