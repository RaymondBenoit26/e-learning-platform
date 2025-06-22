class LicenseAccessesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_student
  before_action :set_license_access, only: [ :show ]

  def index
    @license_accesses = current_user.license_accesses
                                   .joins(:license)
                                   .includes(license: [ :licensable ])
                                   .order(purchased_at: :desc)

    # Apply filters
    if params[:status].present?
      @license_accesses = @license_accesses.where(status: params[:status])
    end

    if params[:payment_method].present?
      payment_ids = current_user.payments
                                .where(payment_method: params[:payment_method])
                                .joins("INNER JOIN licenses ON payments.payable_id = licenses.id AND payments.payable_type = 'License'")
                                .pluck(:payable_id)
      @license_accesses = @license_accesses.where(license_id: payment_ids)
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @license_accesses = @license_accesses.joins(license: :licensable)
                                          .where("licenses.name ILIKE ? OR licenses.licensable_type ILIKE ?",
                                                search_term, search_term)
    end

    # Limit results instead of pagination
    @license_accesses = @license_accesses.limit(50)

    # Statistics
    @total_accesses = current_user.license_accesses.count
    @active_accesses = current_user.license_accesses.where(status: :active).count
    @pending_accesses = current_user.license_accesses.where(status: :pending).count
    @expired_accesses = current_user.license_accesses.where(status: :expired).count

    # Calculate total spent using payments
    @total_spent = current_user.payments
                              .joins("INNER JOIN licenses ON payments.payable_id = licenses.id AND payments.payable_type = 'License'")
                              .where(status: :completed)
                              .sum(:amount)

    # Payment method statistics
    @payment_method_stats = current_user.payments
                                       .joins("INNER JOIN licenses ON payments.payable_id = licenses.id AND payments.payable_type = 'License'")
                                       .where(status: :completed)
                                       .group(:payment_method)
                                       .sum(:amount)
  end

  def show
    @payment = @license_access.payment
    @enrollment = current_user.enrollments.find_by(
      enrollable: @license_access.license.licensable,
      enrollment_type: :license_based
    )
  end

  private

  def set_license_access
    @license_access = current_user.license_accesses.find(params[:id])
  end

  def ensure_student
    unless current_user.student?
      redirect_to root_path, alert: "Access denied. Only students can view license accesses."
    end
  end
end
