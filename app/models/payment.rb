# Payment model tracks financial transactions in the system
# Uses polymorphic associations to handle payments for different entities:
# - License purchases (direct license payments)
# - Term enrollments (payments for term access)
# - Course enrollments (payments for individual courses)
#
# This model provides a unified way to track revenue across the platform
class Payment < ApplicationRecord
  # Payment belongs to a student (the person making the payment)
  belongs_to :student, class_name: "User"

  # Polymorphic association allows payments for different types of entities
  # payable_type can be "License" or "Enrollment", etc.
  # payable_id references the specific entity being paid for
  belongs_to :payable, polymorphic: true

  # Payment method enum
  enum :payment_method, {
    credit_card: "credit_card",
    debit_card: "debit_card",
    bank_transfer: "bank_transfer",
    paypal: "paypal",
    stripe: "stripe",
    cash: "cash",
    scholarship: "scholarship",
    waived: "waived"
  }.freeze

  # Payment status enum
  enum :status, {
    pending: "pending",
    completed: "completed",
    failed: "failed",
    refunded: "refunded"
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true
  validates :status, presence: true

  # Create breakdown for term enrollment payment
  def create_term_breakdown(term)
    student = self.student

    # Check if this is a direct payment or license payment
    term_enrollment = self.payable
    is_direct_payment = term_enrollment&.direct_payment?

    if is_direct_payment
      # For direct payments, only include new courses
      new_courses = term.payable_courses_for(student)
      courses_breakdown = new_courses.map do |course|
        {
          course_id: course.id,
          course_name: course.name,
          price_at_time: course.price,
          amount: course.price
        }
      end
      total_amount = term.adjusted_total_course_price_for(student)
    else
      # For license payments, include all courses (license price is fixed)
      courses_breakdown = term.courses.map do |course|
        {
          course_id: course.id,
          course_name: course.name,
          price_at_time: course.price,
          amount: course.price
        }
      end
      total_amount = term.total_course_price
    end

    self.breakdown = {
      type: "term_enrollment",
      term_id: term.id,
      term_name: term.name,
      total_amount: total_amount,
      courses: courses_breakdown,
      breakdown_date: Time.current.iso8601
    }
  end

  # Create breakdown for course enrollment payment
  def create_course_breakdown(course)
    self.breakdown = {
      type: "course_enrollment",
      course_id: course.id,
      course_name: course.name,
      price_at_time: course.price,
      amount: course.price,
      breakdown_date: Time.current.iso8601
    }
  end

  # Create breakdown for license purchase payment
  def create_license_breakdown(license)
    self.breakdown = {
      type: "license_purchase",
      license_id: license.id,
      license_name: license.name,
      licensable_type: license.licensable_type,
      licensable_id: license.licensable_id,
      licensable_name: license.licensable.name,
      license_type: license.license_type,
      max_seats: license.max_seats,
      expires_at: license.expires_at&.iso8601,
      price_at_time: license.price,
      amount: license.price,
      breakdown_date: Time.current.iso8601
    }
  end

  # Get breakdown summary for display
  def breakdown_summary
    return "No breakdown available" unless breakdown.present?

    case breakdown["type"]
    when "term_enrollment"
      courses_count = breakdown["courses"]&.length || 0
      "Term: #{breakdown['term_name']} (#{courses_count} courses)"
    when "course_enrollment"
      "Course: #{breakdown['course_name']}"
    when "license_purchase"
      licensable_name = breakdown["licensable_name"] || "Unknown"
      license_name = breakdown["license_name"] || "Unknown License"
      "License: #{license_name} for #{breakdown['licensable_type']} - #{licensable_name}"
    else
      "Unknown breakdown type"
    end
  end

  # Get detailed breakdown for analysis
  def detailed_breakdown
    return nil unless breakdown.present?

    case breakdown["type"]
    when "term_enrollment"
      {
        type: "Term Enrollment",
        term: breakdown["term_name"],
        total: breakdown["total_amount"],
        courses: breakdown["courses"]&.map do |course|
          {
            name: course["course_name"],
            price: course["price_at_time"]
          }
        end
      }
    when "course_enrollment"
      {
        type: "Course Enrollment",
        course: breakdown["course_name"],
        price: breakdown["price_at_time"]
      }
    when "license_purchase"
      {
        type: "License Purchase",
        license: breakdown["license_name"],
        licensable_type: breakdown["licensable_type"],
        licensable_name: breakdown["licensable_name"],
        license_type: breakdown["license_type"],
        max_seats: breakdown["max_seats"],
        expires_at: breakdown["expires_at"],
        price: breakdown["price_at_time"]
      }
    end
  end

  # Check if this is a license purchase payment
  def license_purchase?
    breakdown.present? && breakdown["type"] == "license_purchase"
  end

  # Check if this is a term enrollment payment
  def term_enrollment?
    breakdown.present? && breakdown["type"] == "term_enrollment"
  end

  # Check if this is a course enrollment payment
  def course_enrollment?
    breakdown.present? && breakdown["type"] == "course_enrollment"
  end

  # Check if payment has breakdown data
  def has_breakdown?
    breakdown.present? && breakdown["type"].present?
  end

  # Unified payment lifecycle callbacks
  after_create :enqueue_processing_job, if: :pending?
  after_update :activate_payable_on_completion, if: :saved_change_to_status_to_completed?

  private

  def enqueue_processing_job
    # All payments now use the unified PaymentProcessingJob
    PaymentProcessingJob.set(wait: 1.minute).perform_later(self.id)
  end

  def saved_change_to_status_to_completed?
    saved_change_to_status? && completed?
  end

  def activate_payable_on_completion
    payable.activate
  end
  
end
