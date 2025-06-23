class LicensePurchaseService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :license
  attribute :student
  attribute :payment_method, :string

  validates :license, presence: true
  validates :student, presence: true
  validates :payment_method, presence: true

  def initialize(license:, student:, payment_method: nil)
    @license = license
    @student = student
    @payment_method = payment_method&.presence || default_payment_method
    validate_purchase_eligibility
  end

  def call
    return failure(validation_errors) unless valid?

    ActiveRecord::Base.transaction do
      create_payment
      create_license_access
      success(payment: @payment, license_access: @license_access)
    end
  rescue => e
    failure("Failed to process purchase: #{e.message}")
  end

  private

  attr_reader :license, :student, :payment_method

  def validate_purchase_eligibility
    errors.add(:student, "Only students can purchase licenses") unless student.student?
    errors.add(:license, "License has no available seats") unless license.seats_available?
    errors.add(:license, "License has expired") if license.expired?
    errors.add(:license, "You already have access to this license") if existing_access.present?
    errors.add(:payment_method, "Invalid payment method") unless valid_payment_method?
  end

  def existing_access
    @existing_access ||= license.license_accesses.find_by(student: student)
  end

  def valid_payment_method?
    Payment.payment_methods.key?(payment_method)
  end

  def default_payment_method
    license.price > 0 ? "credit_card" : "waived"
  end

  def amount_to_pay
    return 0 if free_payment_methods.include?(payment_method) || license.price == 0
    license.price || 0
  end

  def free_payment_methods
    %w[scholarship waived]
  end

  def payment_status
    amount_to_pay > 0 && !instant_payment_methods.include?(payment_method) ? "pending" : "completed"
  end

  def instant_payment_methods
    %w[cash scholarship waived]
  end

  def license_access_status
    payment_status == "completed" ? "active" : "pending"
  end

  def create_payment
    @payment = student.payments.build(
      amount: amount_to_pay,
      payment_method: payment_method,
      payable: license,
      status: payment_status
    )

    @payment.create_license_breakdown(license)

    unless @payment.save
      raise "Payment creation failed: #{@payment.errors.full_messages.join(', ')}"
    end
  end

  def create_license_access
    @license_access = license.license_accesses.build(
      student: student,
      purchased_at: Time.current,
      status: license_access_status
    )

    if license.expires_at.present?
      @license_access.expires_at = license.expires_at
    end

    unless @license_access.save
      raise "License access creation failed: #{@license_access.errors.full_messages.join(', ')}"
    end
  end

  def validation_errors
    errors.full_messages.join(", ")
  end

  def success(data = {})
    PurchaseResult.new(success: true, data: data)
  end

  def failure(message)
    PurchaseResult.new(success: false, error: message)
  end

  # Simple result object
  PurchaseResult = Struct.new(:success, :data, :error, keyword_init: true) do
    def success?
      success
    end

    def failure?
      !success
    end
  end
end
