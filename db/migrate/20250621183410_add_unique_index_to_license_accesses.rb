class AddUniqueIndexToLicenseAccesses < ActiveRecord::Migration[7.1]
  def change
    add_index :license_accesses, [ :student_id, :license_id ], unique: true
  end
end
