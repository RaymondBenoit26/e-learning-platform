class Enrollment < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :enrollable, polymorphic: true  # Can be Course or Term
  belongs_to :license_access, optional: true # Only for license-based enrollments
  has_many :payments, as: :payable, dependent: :destroy

  # Enrollment status enum
  enum :status, {
    pending: "pending",
    active: "active",
    completed: "completed",
    cancelled: "cancelled",
    suspended: "suspended"
  }, default: "pending"

  # Enrollment type enum - tracks how the student enrolled
  enum :enrollment_type, {
    course: "course",
    term: "term",
    license_based: "license_based",
    direct_payment: "direct_payment",
    free: "free"
  }, default: "course"

  validates :enrollment_type, presence: true
  validates :student_id, uniqueness: {
    scope: [ :enrollable_type, :enrollable_id, :enrollment_type ],
    message: "Student is already enrolled in this item"
  }

  # Validate that license-based enrollments have license_access
  validates :license_access_id, presence: true, if: :license_based?
  validates :license_access_id, absence: true, unless: :license_based?

  # Scopes for different enrollment types
  scope :course_enrollments, -> { where(enrollable_type: "Course") }
  scope :term_enrollments, -> { where(enrollable_type: "Term") }
  scope :license_based, -> { where(enrollment_type: "license_based") }
  scope :direct_payment, -> { where(enrollment_type: "direct_payment") }
  scope :free_enrollments, -> { where(enrollment_type: "free") }

  # Term-specific scopes (only apply to term enrollments)
  scope :current_terms, -> {
    term_enrollments.joins("INNER JOIN terms ON terms.id = enrollments.enrollable_id")
                   .where("terms.start_date <= ? AND terms.end_date >= ?", Date.current, Date.current)
  }
  scope :upcoming_terms, -> {
    term_enrollments.joins("INNER JOIN terms ON terms.id = enrollments.enrollable_id")
                   .where("terms.start_date > ?", Date.current)
  }
  scope :completed_terms, -> {
    term_enrollments.joins("INNER JOIN terms ON terms.id = enrollments.enrollable_id")
                   .where("terms.end_date < ?", Date.current)
  }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "updated_at", "enrollable_type", "enrollable_id", "student_id", "enrollment_type", "status", "course_name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "enrollable", "student", "license_access" ]
  end

  # Helper methods for easier access to enrollable types
  def course
    enrollable if enrollable_type == "Course"
  end

  def term
    enrollable if enrollable_type == "Term"
  end

  # Check if enrollment is for a course
  def course_enrollment?
    enrollable_type == "Course"
  end

  # Check if enrollment is for a term
  def term_enrollment?
    enrollable_type == "Term"
  end

  # Check if the term has ended (for term enrollments)
  def expired?
    return false unless term_enrollment?
    enrollable.end_date < Date.current
  end

  # Check if enrollment is within the active term period (for term enrollments)
  def active_period?
    return false unless term_enrollment?
    enrollable.start_date <= Date.current && enrollable.end_date >= Date.current
  end

  # Check if enrollment is affected by license expiration (for license-based enrollments)
  def license_expired?
    return false unless license_based?
    license_access&.license&.expired?
  end

  # Check if user has valid access
  def has_valid_access?
    return false unless active?

    case enrollment_type
    when "license_based"
      license_access&.active? && !license_expired?
    when "direct_payment"
      payment_completed? && (course_enrollment? || !expired?)
    when "free"
      course_enrollment? || !expired?
    else
      true
    end
  end

  # Get human-readable reason for access restriction
  def access_restriction_reason
    return nil if has_valid_access?

    if suspended?
      "Enrollment suspended"
    elsif cancelled?
      "Enrollment cancelled"
    elsif completed?
      "Enrollment completed"
    elsif license_based? && license_expired?
      "License expired on #{license_access.license.expires_at&.strftime('%B %d, %Y')}"
    elsif license_based? && !license_access&.active?
      "License access is not active"
    elsif term_enrollment? && expired?
      "Term ended on #{enrollable.end_date.strftime('%B %d, %Y')}"
    elsif direct_payment? && !payment_completed?
      "Payment not completed"
    else
      "Access restricted"
    end
  end

  # Check if user can renew their license (for license-based enrollments)
  def can_renew_license?
    license_based? && license_expired? && term_enrollment? && enrollable.end_date >= Date.current
  end

  # Check if this is a license-based enrollment
  def license_based?
    enrollment_type == "license_based"
  end

  # Check if this is a direct payment enrollment
  def direct_payment?
    enrollment_type == "direct_payment"
  end

  # Check if this is a free enrollment
  def free?
    enrollment_type == "free"
  end

  # Check if enrollment is free (no payment required)
  def free_enrollment?
    free? || (enrollable.respond_to?(:price) && enrollable.price&.zero?)
  end

  # Get the total amount paid for this enrollment
  def total_paid
    payments.completed.sum(:amount)
  end

  # Check if payment is required for this enrollment
  def payment_required?
    case enrollment_type
    when "license_based"
      license_access&.license&.price&.positive?
    when "direct_payment"
      true
    when "free"
      false
    else
      false
    end
  end

  # Get the enrollment cost (for display purposes)
  def enrollment_cost
    case enrollment_type
    when "license_based"
      license_access&.license&.price || 0
    when "direct_payment"
      total_paid
    when "free"
      0
    else
      0
    end
  end

  # Get the license for license-based enrollments
  def license
    license_access&.license
  end

  # Returns the course name if enrollable is a Course, otherwise nil
  def course_name
    enrollable.is_a?(Course) ? enrollable.name : nil
  end

  # Get the latest payment for this enrollment
  def latest_payment
    payments.order(created_at: :desc).first
  end

  def payment_pending?
    latest_payment&.pending?
  end

  def payment_completed?
    latest_payment&.completed?
  end

  def payment_failed?
    latest_payment&.failed?
  end

  def activate
    update!(status: :active)
  end
end
