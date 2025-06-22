class AddDescriptionToTerms < ActiveRecord::Migration[8.0]
  def change
    add_column :terms, :description, :text
  end
end
