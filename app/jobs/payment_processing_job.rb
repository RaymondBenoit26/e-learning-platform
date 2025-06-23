class PaymentProcessingJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.find_by(id: payment_id)
    return unless payment&.pending?

    process_payment(payment)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Payment not found in PaymentProcessingJob: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error processing payment #{payment_id}: #{e.message}"
    payment&.update(status: :failed)
  end

  private

  def process_payment(payment)
    # Simulate payment processing
    sleep(30.seconds) if Rails.env.development?

    ActiveRecord::Base.transaction do
      payment.update!(status: :completed)
    end
  end
end
