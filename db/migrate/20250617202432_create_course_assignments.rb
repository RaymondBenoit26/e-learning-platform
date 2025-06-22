class CreateCourseAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :course_assignments do |t|
      t.references :instructor, null: false, foreign_key: { to_table: :users }
      t.references :course, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
