class AddAddressFieldsToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :city, :string
    add_column :schools, :state, :string
    add_column :schools, :zip_code, :string
  end
end
