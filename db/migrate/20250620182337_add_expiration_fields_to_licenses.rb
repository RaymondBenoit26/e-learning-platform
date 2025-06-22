class AddExpirationFieldsToLicenses < ActiveRecord::Migration[8.0]
  def change
    add_column :licenses, :expires_at, :datetime
    add_column :licenses, :license_type, :string
  end
end
