class RemovePaymentFieldsFromLicenseAccesses < ActiveRecord::Migration[8.0]
  def up
    remove_column :license_accesses, :payment_method, :string
    remove_column :license_accesses, :amount_paid, :decimal
    remove_column :license_accesses, :payment_reference, :string
  end

  def down
    add_column :license_accesses, :payment_method, :string, default: "waived"
    add_column :license_accesses, :amount_paid, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :license_accesses, :payment_reference, :string

    # Add indexes for performance
    add_index :license_accesses, :payment_method
  end
end
