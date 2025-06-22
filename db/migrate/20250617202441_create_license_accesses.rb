class CreateLicenseAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :license_accesses do |t|
      t.references :license, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.string :status

      t.timestamps
    end
  end
end
