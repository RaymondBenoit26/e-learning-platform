# LicenseAccess model represents the relationship between students and licenses
# This is a join table that tracks which students have purchased which licenses
# It's essential for enforcing license seat limits and tracking usage
class LicenseAccess < ApplicationRecord
  belongs_to :license
  belongs_to :student, class_name: "User"

  # Status enum for license access
  enum :status, {
    pending: "pending",
    active: "active",
    expired: "expired",
    cancelled: "cancelled"
  }, default: "pending"

  # Ensure a student can only purchase a license once
  # This prevents duplicate purchases and maintains data integrity
  validates :license_id, uniqueness: { scope: :student_id, message: "has already been purchased by this student" }

  # Automatically create enrollment when license access becomes active
  after_update :create_enrollment_if_active, if: :saved_change_to_status?
  after_create :create_enrollment_if_active, if: :active?

  # Get the payment for this license access
  def payment
    student.payments.find_by(payable: license)
  end

  # Check if this license access has a payment
  def has_payment?
    payment.present?
  end

  # Get payment method from associated payment
  def payment_method
    payment&.payment_method
  end

  # Get payment method display name
  def payment_method_display
    return "Free" unless has_payment?

    case payment.payment_method
    when "credit_card"
      "Credit Card"
    when "debit_card"
      "Debit Card"
    when "bank_transfer"
      "Bank Transfer"
    when "paypal"
      "PayPal"
    when "stripe"
      "Stripe"
    when "cash"
      "Cash"
    when "scholarship"
      "Scholarship"
    when "waived"
      "Waived"
    else
      payment.payment_method&.humanize || "Unknown"
    end
  end

  # Get amount paid from associated payment
  def amount_paid
    payment&.amount || 0
  end

  # Check if this is a paid license access
  def paid?
    has_payment? && amount_paid > 0 && !%w[scholarship waived].include?(payment_method)
  end

  # Check if this is a free license access
  def free?
    !has_payment? || amount_paid == 0 || %w[scholarship waived].include?(payment_method)
  end

  private

  def create_enrollment_if_active
    return unless active?
    return if enrollment_exists?

    # Create enrollment based on license type
    enrollment = student.enrollments.build(
      enrollable: license.licensable,
      enrollment_type: :license_based,
      status: :active,
      payable: payment # Link to the payment if it exists
    )

    if enrollment.save
      Rails.logger.info "Enrollment created for student #{student.email} in #{license.licensable_type} #{license.licensable.name} via license #{license.name}"
    else
      Rails.logger.error "Failed to create enrollment for license access #{id}: #{enrollment.errors.full_messages.join(', ')}"
    end
  end

  def enrollment_exists?
    student.enrollments.exists?(
      enrollable: license.licensable,
      enrollment_type: :license_based
    )
  end
end
