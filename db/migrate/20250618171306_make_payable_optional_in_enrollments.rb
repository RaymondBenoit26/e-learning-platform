class MakePayableOptionalInEnrollments < ActiveRecord::Migration[8.0]
  def change
    change_column_null :enrollments, :payable_type, true
    change_column_null :enrollments, :payable_id, true
  end
end
