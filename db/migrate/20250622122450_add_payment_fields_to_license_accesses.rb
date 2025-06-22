class AddPaymentFieldsToLicenseAccesses < ActiveRecord::Migration[8.0]
  def change
    # Status column already exists, so we'll just add the missing columns
    add_column :license_accesses, :payment_method, :string, null: false, default: "free"
    add_column :license_accesses, :amount_paid, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :license_accesses, :payment_reference, :string # For external payment system references
    add_column :license_accesses, :purchased_at, :datetime # When the license was purchased
    add_column :license_accesses, :expires_at, :datetime # When the license access expires (can be different from license expiry)

    # Add indexes for better performance
    add_index :license_accesses, :payment_method
    add_index :license_accesses, :purchased_at
    add_index :license_accesses, :expires_at

    # Update existing records to have active status and free payment method
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE license_accesses#{' '}
          SET payment_method = 'free',#{' '}
              amount_paid = 0.0,
              purchased_at = created_at
          WHERE payment_method IS NULL
        SQL

        # Update status to 'active' for existing records that might be null
        execute <<-SQL
          UPDATE license_accesses#{' '}
          SET status = 'active'
          WHERE status IS NULL OR status = ''
        SQL
      end
    end
  end
end
