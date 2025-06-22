class FixPendingEnrollmentsJob < ApplicationJob
  queue_as :default

  def perform
    fix_pending_enrollments
  end

  private

  def fix_pending_enrollments
    pending_enrollments = Enrollment.where(status: "pending")

    pending_enrollments.each do |enrollment|
      # Check if there's a payment for this enrollment
      payment = Payment.find_by(payable: enrollment)

      if payment&.completed?
        # Payment exists and is completed, activate enrollment
        enrollment.update(status: :active)
        Rails.logger.info "Activated enrollment #{enrollment.id} (payment completed)"
      elsif enrollment.course_enrollment? && enrollment.enrollable.free?
        # Free course, activate enrollment
        enrollment.update(status: :active)
        Rails.logger.info "Activated enrollment #{enrollment.id} (free course)"
      elsif enrollment.term_enrollment? && enrollment.free?
        # Free term enrollment, activate it
        enrollment.update(status: :active)
        Rails.logger.info "Activated enrollment #{enrollment.id} (free term enrollment)"
      elsif payment&.pending?
        # Payment is pending, leave enrollment pending
        Rails.logger.info "Enrollment #{enrollment.id} remains pending (payment pending)"
      else
        # No payment for paid enrollment - this is an inconsistency
        # For now, we'll mark it as cancelled, but in a real system you might want to handle this differently
        enrollment.update(status: :cancelled)
        Rails.logger.warn "Cancelled enrollment #{enrollment.id} (no payment for paid enrollment)"
      end
    end
  end
end
