class AddEnrollmentTypeToEnrollments < ActiveRecord::Migration[8.0]
  def change
    add_column :enrollments, :enrollment_type, :string, default: 'course'
    add_index :enrollments, :enrollment_type
  end
end
