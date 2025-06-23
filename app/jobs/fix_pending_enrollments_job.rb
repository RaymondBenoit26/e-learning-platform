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
      elsif enrollment.course_enrollment? && enrollment.enrollable.free?
        # Free course, activate enrollment
        enrollment.update(status: :active)
      elsif enrollment.term_enrollment? && enrollment.free?
        # Free term enrollment, activate it
        enrollment.update(status: :active)
      elsif payment&.pending?
        # Payment is pending, leave enrollment pending
      else
        # No payment for paid enrollment - this is an inconsistency
        enrollment.update(status: :cancelled)
      end
    end
  end
end
