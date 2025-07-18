class CreateChapters < ActiveRecord::Migration[8.0]
  def change
    create_table :chapters do |t|
      t.string :title
      t.text :description
      t.integer :order
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
