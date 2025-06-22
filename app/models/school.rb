class School < ApplicationRecord
  has_many :terms, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :users, dependent: :destroy

  # Scoped associations for different user types
  has_many :students, -> { where(user_type: :student) }, class_name: "User"
  has_many :instructors, -> { where(user_type: :instructor) }, class_name: "User"
  has_many :management_users, -> { where(user_type: :management) }, class_name: "User"

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "domain", "address", "city", "state", "zip_code", "phone", "email", "website", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "users", "students", "instructors", "management_users", "courses", "terms" ]
  end
end
