class AddBreakdownToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :breakdown, :json
  end
end
