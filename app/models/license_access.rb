# LicenseAccess model represents the relationship between students and licenses
# This is a join table that tracks which students have purchased which licenses
# It's essential for enforcing license seat limits and tracking usage
class LicenseAccess < ApplicationRecord
  belongs_to :license
  belongs_to :student, class_name: "User"
  has_one :enrollment, dependent: :destroy # Clean 1:1 relationship

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

  # Callbacks for license access lifecycle
  # When license access becomes active, automatically create enrollment
  after_update :create_enrollment_if_activated, if: :saved_change_to_status_to_active?
  after_create :create_enrollment_if_active, if: :active?

  # Get the payment for this license access (payment.payable points to the license)
  def payment
    student.payments.find_by(payable_type: "License", payable_id: license_id)
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
    payment.payment_method.humanize
  end

  def amount_paid
    payment&.amount || 0
  end

  def paid?
    has_payment? && amount_paid > 0 && !%w[scholarship waived].include?(payment_method)
  end

  # Check if this is a free license access
  def free?
    !has_payment? || amount_paid == 0 || %w[scholarship waived].include?(payment_method)
  end

  private

  def saved_change_to_status_to_active?
    saved_change_to_status? && active?
  end

  def create_enrollment_if_activated
    create_enrollment_if_active
  end

  def create_enrollment_if_active
    return unless active?
    return if enrollment.present? && enrollment.status.active?

    new_enrollment = student.enrollments.build(
      enrollable: license.licensable,
      enrollment_type: :license_based,
      status: :active,
      license_access: self
    )

    if new_enrollment.save
      Rails.logger.info "Created enrollment #{new_enrollment.id} for license access #{id}"
    else
      Rails.logger.error "Failed to create enrollment for license access #{id}: #{new_enrollment.errors.full_messages.join(', ')}"
    end
  end
end
