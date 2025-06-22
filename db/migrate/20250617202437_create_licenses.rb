class CreateLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :licenses do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.integer :max_seats
      t.date :valid_until
      t.references :term, null: false, foreign_key: true

      t.timestamps
    end
  end
end
