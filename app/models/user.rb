class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :school, optional: true

  # User type enum
  enum :user_type, {
    student: 0,
    instructor: 1,
    management: 2,
    super_admin: 3
  }

  # Student associations - unified enrollment system
  has_many :enrollments, dependent: :destroy, foreign_key: "student_id"
  has_many :course_enrollments, -> { course_enrollments }, class_name: "Enrollment", foreign_key: "student_id"
  has_many :term_enrollments, -> { term_enrollments }, class_name: "Enrollment", foreign_key: "student_id"
  has_many :courses, through: :course_enrollments, source: :enrollable, source_type: "Course"
  has_many :terms, through: :term_enrollments, source: :enrollable, source_type: "Term"
  has_many :payments, dependent: :destroy, foreign_key: "student_id"
  has_many :license_accesses, dependent: :destroy, foreign_key: "student_id"
  has_many :licenses, through: :license_accesses

  # Instructor associations
  has_many :course_assignments, dependent: :destroy, foreign_key: "instructor_id"
  has_many :assigned_courses, through: :course_assignments, source: :course

  # Scopes for different user types
  scope :students, -> { where(user_type: :student) }
  scope :instructors, -> { where(user_type: :instructor) }
  scope :management, -> { where(user_type: :management) }
  scope :super_admins, -> { where(user_type: :super_admin) }

  # Ransack configuration for admin search functionality
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "first_name", "last_name", "email", "user_type", "school_id", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "school", "enrollments", "courses", "terms", "payments", "license_accesses", "licenses", "course_assignments", "assigned_courses" ]
  end

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :user_type, presence: true

  # Helper methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin?
    management?
  end

  # For CanCan compatibility
  def role
    user_type
  end

  # Enrollment helper methods
  def enrolled_in_course?(course)
    course_enrollments.exists?(enrollable: course)
  end

  def enrolled_in_term?(term)
    term_enrollments.exists?(enrollable: term)
  end

  def active_course_enrollments
    course_enrollments.active
  end

  def active_term_enrollments
    term_enrollments.active
  end

  def current_term_enrollments
    term_enrollments.current_terms
  end

  def upcoming_term_enrollments
    term_enrollments.upcoming_terms
  end

  def completed_term_enrollments
    term_enrollments.completed_terms
  end
end
