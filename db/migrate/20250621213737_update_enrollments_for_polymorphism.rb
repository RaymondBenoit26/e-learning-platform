class UpdateEnrollmentsForPolymorphism < ActiveRecord::Migration[8.0]
  def up
    # Add polymorphic columns to enrollments table
    add_column :enrollments, :enrollable_type, :string
    add_column :enrollments, :enrollable_id, :bigint

    # Add index for polymorphic association
    add_index :enrollments, [ :enrollable_type, :enrollable_id ]

    # Migrate existing course enrollments
    execute <<-SQL
      UPDATE enrollments#{' '}
      SET enrollable_type = 'Course', enrollable_id = course_id#{' '}
      WHERE course_id IS NOT NULL
    SQL

    # Migrate term enrollments to the enrollments table
    execute <<-SQL
      INSERT INTO enrollments (
        student_id, enrollable_type, enrollable_id, payable_type, payable_id,#{' '}
        status, enrollment_type, created_at, updated_at
      )
      SELECT#{' '}
        student_id, 'Term', term_id, payable_type, payable_id,
        status, enrollment_type, created_at, updated_at
      FROM term_enrollments
    SQL

    # Remove the old course_id column from enrollments
    remove_column :enrollments, :course_id

    # Drop the term_enrollments table
    drop_table :term_enrollments
  end

  def down
    # Recreate term_enrollments table
    create_table :term_enrollments do |t|
      t.bigint :student_id, null: false
      t.bigint :term_id, null: false
      t.bigint :license_id
      t.string :status, default: "active"
      t.string :payable_type
      t.bigint :payable_id
      t.string :enrollment_type, default: "license_based"
      t.timestamps

      t.index [ :student_id, :term_id ], unique: true
      t.index :student_id
      t.index :term_id
      t.index :license_id
      t.index :enrollment_type
      t.index [ :payable_type, :payable_id ]
    end

    # Add course_id column back to enrollments
    add_column :enrollments, :course_id, :bigint
    add_index :enrollments, :course_id

    # Migrate term enrollments back
    execute <<-SQL
      INSERT INTO term_enrollments (
        student_id, term_id, license_id, status, payable_type, payable_id,
        enrollment_type, created_at, updated_at
      )
      SELECT#{' '}
        student_id, enrollable_id, payable_id, status, payable_type, payable_id,
        enrollment_type, created_at, updated_at
      FROM enrollments#{' '}
      WHERE enrollable_type = 'Term'
    SQL

    # Migrate course enrollments back
    execute <<-SQL
      UPDATE enrollments#{' '}
      SET course_id = enrollable_id#{' '}
      WHERE enrollable_type = 'Course'
    SQL

    # Remove polymorphic columns
    remove_column :enrollments, :enrollable_type
    remove_column :enrollments, :enrollable_id

    # Remove polymorphic index
    remove_index :enrollments, [ :enrollable_type, :enrollable_id ], if_exists: true
  end
end
