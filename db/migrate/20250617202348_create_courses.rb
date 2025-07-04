class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.text :description
      t.references :school, null: false, foreign_key: true
      t.references :term, null: true, foreign_key: true

      t.timestamps
    end
  end
end
