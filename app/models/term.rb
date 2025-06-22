class Term < ApplicationRecord
  belongs_to :school
  has_many :courses, dependent: :destroy
  has_many :licenses, as: :licensable, dependent: :destroy
  has_many :enrollments, as: :enrollable, dependent: :destroy
  has_many :enrolled_students, through: :enrollments, class_name: "User"

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :upcoming, -> { where("start_date > ?", Date.current) }
  scope :completed, -> { where("end_date < ?", Date.current) }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "description", "start_date", "end_date", "created_at", "updated_at", "school_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "school", "courses", "licenses", "enrollments", "enrolled_students" ]
  end

  def status
    if start_date > Date.current
      "upcoming"
    elsif end_date < Date.current
      "completed"
    else
      "current"
    end
  end

  def duration_in_days
    (end_date - start_date).to_i
  end

  # Calculate total price of all courses in this term
  def total_course_price
    courses.sum(:price) || 0
  end

  # Check if term has any paid courses
  def has_paid_courses?
    courses.where("price > 0").exists?
  end

  # Check if term is completely free
  def free?
    total_course_price.zero?
  end

  # Get recommended license price based on course total
  def recommended_license_price
    total = total_course_price
    if total.zero?
      0
    else
      # Apply a small discount for term enrollment (e.g., 10% off)
      (total * 0.9).round(2)
    end
  end

  # Display the total course price
  def total_price_display
    return "Free" if free?
    "$#{total_course_price}"
  end

  # Get courses grouped by price
  def courses_by_price
    courses.group_by(&:price_display)
  end

  # Returns courses in this term the student has NOT already purchased
  def payable_courses_for(student)
    courses.where.not(id: student.course_enrollments.where(status: "active").pluck(:enrollable_id))
  end

  # Returns courses in this term the student has already purchased
  def already_purchased_courses_for(student)
    courses.where(id: student.course_enrollments.where(status: "active").pluck(:enrollable_id))
  end

  # Returns the sum of prices for only the courses not already purchased
  def adjusted_total_course_price_for(student)
    payable_courses_for(student).sum(:price) || 0
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after the start date") if end_date <= start_date
  end
end
