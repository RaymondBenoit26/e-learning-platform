class LicensePaymentProcessingJob < ApplicationJob
  queue_as :default

  def perform(license_access_id, payment_id)
    license_access = LicenseAccess.find(license_access_id)
    payment = Payment.find(payment_id)

    Rails.logger.info "Processing license payment for License Access #{license_access_id}, Payment #{payment_id}"

    # Simulate payment processing time based on payment method
    processing_delay = case payment.payment_method
    when "credit_card", "debit_card"
                        rand(30..120) # 30 seconds to 2 minutes
    when "bank_transfer"
                        rand(300..900) # 5 to 15 minutes
    when "paypal", "stripe"
                        rand(60..180) # 1 to 3 minutes
    else
                        10 # Immediate for other methods
    end

    sleep(processing_delay) if Rails.env.development? # Only sleep in development

    # Simulate payment success/failure rates
    success_rate = case payment.payment_method
    when "credit_card", "debit_card"
                    0.95 # 95% success rate
    when "bank_transfer"
                    0.98 # 98% success rate
    when "paypal", "stripe"
                    0.97 # 97% success rate
    else
                    1.0 # 100% success for other methods
    end

    payment_successful = rand < success_rate

    ActiveRecord::Base.transaction do
      if payment_successful
        payment.update!(status: :completed)
        license_access.update!(status: :active)
      else
        payment.update!(status: :failed)
        license_access.update!(status: :cancelled)
      end
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record not found in LicensePaymentProcessingJob: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error processing license payment: #{e.message}"
    # On error, mark payment as failed and cancel license access
    begin
      payment&.update(status: :failed)
      license_access&.update(status: :cancelled)
    rescue => inner_e
      Rails.logger.error "Failed to update records after error: #{inner_e.message}"
    end
  end
end
