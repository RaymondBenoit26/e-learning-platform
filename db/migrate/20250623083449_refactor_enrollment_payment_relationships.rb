class RefactorEnrollmentPaymentRelationships < ActiveRecord::Migration[8.0]
  def up
    # Add license_access_id to enrollments for license-based enrollments
    add_reference :enrollments, :license_access, null: true, foreign_key: true

    # Remove the confusing payable polymorphic association from enrollments
    # Keep it simple - enrollments should only track what user is enrolled in
    remove_reference :enrollments, :payable, polymorphic: true

    # Update existing license-based enrollments to link to license_access
    execute <<-SQL
      UPDATE enrollments#{' '}
      SET license_access_id = (
        SELECT la.id#{' '}
        FROM license_accesses la#{' '}
        INNER JOIN licenses l ON la.license_id = l.id#{' '}
        WHERE la.student_id = enrollments.student_id#{' '}
        AND l.licensable_type = enrollments.enrollable_type#{' '}
        AND l.licensable_id = enrollments.enrollable_id#{' '}
        AND enrollments.enrollment_type = 'license_based'
        LIMIT 1
      )
      WHERE enrollments.enrollment_type = 'license_based'
    SQL

    # Clean up any orphaned data
    execute <<-SQL
      DELETE FROM enrollments#{' '}
      WHERE enrollment_type = 'license_based'#{' '}
      AND license_access_id IS NULL
    SQL
  end

  def down
    # Re-add the payable polymorphic association
    add_reference :enrollments, :payable, polymorphic: true

    # Restore the payable relationship for license-based enrollments
    execute <<-SQL
      UPDATE enrollments#{' '}
      SET payable_type = 'License',#{' '}
          payable_id = (
            SELECT la.license_id#{' '}
            FROM license_accesses la#{' '}
            WHERE la.id = enrollments.license_access_id
          )
      WHERE enrollment_type = 'license_based'#{' '}
      AND license_access_id IS NOT NULL
    SQL

    # Remove the license_access_id column
    remove_reference :enrollments, :license_access
  end
end
