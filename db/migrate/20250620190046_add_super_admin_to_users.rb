class AddSuperAdminToUsers < ActiveRecord::Migration[8.0]
  def up
    # First, let's update the user_type enum to include super_admin (value 3)
    # We need to add it to the database level constraint if any exists

    # Make school_id optional for super admins
    change_column_null :users, :school_id, true

    # Add super_admin user type (enum value 3)
    # This will be handled in the model enum definition
  end

  def down
    # Remove any super_admin users before rolling back
    User.where(user_type: 3).destroy_all

    # Make school_id required again
    change_column_null :users, :school_id, false
  end
end
