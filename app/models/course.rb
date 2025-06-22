class Course < ApplicationRecord
  belongs_to :school
  belongs_to :term, optional: true

  has_many :chapters, dependent: :destroy
  has_many :course_contents, dependent: :destroy
  has_many :enrollments, as: :enrollable, dependent: :destroy
  has_many :students, through: :enrollments, class_name: "User"
  has_many :course_assignments, dependent: :destroy
  has_many :instructors, through: :course_assignments, class_name: "User"
  has_many :licenses, as: :licensable, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "description", "price", "created_at", "updated_at", "school_id", "term_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "school", "term", "instructors", "students", "enrollments", "chapters", "course_contents", "licenses" ]
  end

  def free?
    price.nil? || price.zero?
  end

  def price_display
    if free?
      "Free"
    else
      "$#{price}"
    end
  end
end
