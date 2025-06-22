class CreateCourseContents < ActiveRecord::Migration[8.0]
  def change
    create_table :course_contents do |t|
      t.string :title
      t.text :description
      t.string :content_type
      t.references :course, null: false, foreign_key: true
      t.references :chapter, null: true, foreign_key: true

      t.timestamps
    end
  end
end
