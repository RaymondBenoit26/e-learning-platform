class PaymentProcessingJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.find_by(id: payment_id)
    return unless payment && payment.pending?

    # Simulate payment processing with realistic delays
    process_payment(payment)
  end

  private

  def process_payment(payment)
    # Simulate payment processing time (1-3 minutes)
    processing_time = rand(60..180)
    sleep(processing_time)

    # Simulate payment success/failure (95% success rate)
    if rand < 0.95
      payment.update(status: :completed)
      process_payable(payment.payable)
    else
      payment.update(status: :failed)
    end
  end

  def process_payable(payable)
    case payable
    when Enrollment
      process_enrollment(payable)
    end
  end

  def process_enrollment(enrollment)
    return unless enrollment.pending?

    if enrollment.course_enrollment? || enrollment.term_enrollment?
      # For course enrollments, activate if payment is completed
      enrollment.update(status: :active)
    end
  end
end
