class AddDefaultStatusToEnrollments < ActiveRecord::Migration[8.0]
  def change
    change_column_default :enrollments, :status, "pending"
  end
end
