class AddWebsiteToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :website, :string
  end
end
