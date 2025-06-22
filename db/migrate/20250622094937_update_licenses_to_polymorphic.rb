class UpdateLicensesToPolymorphic < ActiveRecord::Migration[8.0]
  def up
    # Add new polymorphic columns
    add_column :licenses, :licensable_type, :string
    add_column :licenses, :licensable_id, :bigint

    # Add index for polymorphic association
    add_index :licenses, [ :licensable_type, :licensable_id ]

    # Migrate existing data - all existing licenses are for terms
    execute "UPDATE licenses SET licensable_type = 'Term', licensable_id = term_id WHERE term_id IS NOT NULL"

    # Remove the old term_id column
    remove_column :licenses, :term_id
  end

  def down
    # Add back the term_id column
    add_column :licenses, :term_id, :bigint

    # Migrate data back - only for Term licenses
    execute "UPDATE licenses SET term_id = licensable_id WHERE licensable_type = 'Term'"

    # Remove polymorphic columns
    remove_index :licenses, [ :licensable_type, :licensable_id ]
    remove_column :licenses, :licensable_type
    remove_column :licenses, :licensable_id
  end
end
