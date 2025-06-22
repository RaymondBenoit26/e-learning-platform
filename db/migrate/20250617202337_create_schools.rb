class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :domain
      t.text :address
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
