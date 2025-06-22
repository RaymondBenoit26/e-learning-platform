class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.decimal :amount
      t.string :payment_method
      t.string :status
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :payable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
