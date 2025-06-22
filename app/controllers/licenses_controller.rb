class LicensesController < ApplicationController
  before_action :set_school
  before_action :set_license, only: [ :show, :edit, :update, :destroy, :purchase ]
  before_action :ensure_management_user, except: [ :index, :show, :purchase ]

  def index
    if current_user.super_admin?
      # Super admin sees all licenses across all schools
      @licenses = License.includes(:license_accesses, :students)

      # Apply search filter
      if params[:search].present?
        @licenses = @licenses.where("licenses.name ILIKE ? OR licenses.description ILIKE ?",
                                   "%#{params[:search]}%", "%#{params[:search]}%")
      end

      # Apply license type filter
      if params[:license_type].present?
        @licenses = @licenses.where(license_type: params[:license_type])
      end

      # Apply status filter
      if params[:status].present?
        case params[:status]
        when "active"
          @licenses = @licenses.active
        when "expired"
          @licenses = @licenses.expired
        when "available"
          @licenses = @licenses.available
        end
      end

      @licenses = @licenses.order(created_at: :desc)
    else
      # Regular users see licenses for their school only
      @licenses = License.where(licensable_type: "Term")
                        .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                        .where(terms: { school_id: @school.id })
                        .includes(:license_accesses, :students)

      # Apply search filter
      if params[:search].present?
        @licenses = @licenses.where("licenses.name ILIKE ? OR licenses.description ILIKE ?",
                                   "%#{params[:search]}%", "%#{params[:search]}%")
      end

      # Apply license type filter
      if params[:license_type].present?
        @licenses = @licenses.where(license_type: params[:license_type])
      end

      # Apply status filter
      if params[:status].present?
        case params[:status]
        when "active"
          @licenses = @licenses.active
        when "expired"
          @licenses = @licenses.expired
        when "available"
          @licenses = @licenses.available
        end
      end

      @licenses = @licenses.order(created_at: :desc)

      # Usage statistics for admin
      if current_user.management?
        license_ids = @licenses.pluck(:id)
        @total_revenue = Payment.where(payable_type: "License", payable_id: license_ids).sum(:amount)

        # Get most popular license by counting license accesses
        @most_popular_license = License.where(licensable_type: "Term")
                                      .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                                      .left_joins(:license_accesses)
                                      .where(terms: { school_id: @school.id })
                                      .group("licenses.id")
                                      .order("COUNT(license_accesses.id) DESC")
                                      .first
      end
    end
  end

  def show
    @available_seats = @license.available_seats
    @enrolled_students = @license.students.includes(:school)
  end

  def new
    if current_user.super_admin?
      @license = Term.find(params[:term_id]).licenses.build if params[:term_id]
      @license ||= License.new
      @terms = Term.order(:start_date)
    else
      @license = @school.terms.find(params[:term_id]).licenses.build if params[:term_id]
      @license ||= License.new
      @terms = @school.terms.order(:start_date)
    end
  end

  def create
    if current_user.super_admin?
      @term = Term.find(license_params[:term_id])
      @license = @term.licenses.build(license_params.except(:term_id))

      if @license.save
        redirect_to [ @license.licensable.school, @license.licensable, @license ], notice: "License was successfully created."
      else
        @terms = Term.order(:start_date)
        render :new, status: :unprocessable_entity
      end
    else
      @term = @school.terms.find(license_params[:term_id])
      @license = @term.licenses.build(license_params.except(:term_id))

      if @license.save
        redirect_to [ @school, @term, @license ], notice: "License was successfully created."
      else
        @terms = @school.terms.order(:start_date)
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    if current_user.super_admin?
      @terms = Term.order(:start_date)
    else
      @terms = @school.terms.order(:start_date)
    end
  end

  def update
    # Custom validation for max_seats
    if license_params[:max_seats].present? && license_params[:max_seats].to_i < @license.students.count
      @license.errors.add(:max_seats, "cannot be less than current usage (#{@license.students.count} seats)")
      if current_user.super_admin?
        @terms = Term.order(:start_date)
      else
        @terms = @school.terms.order(:start_date)
      end
      render :edit, status: :unprocessable_entity
      return
    end

    # Handle term_id update by setting the polymorphic association
    update_params = license_params.except(:term_id)
    if license_params[:term_id].present?
      term = current_user.super_admin? ? Term.find(license_params[:term_id]) : @school.terms.find(license_params[:term_id])
      update_params[:licensable] = term
    end

    if @license.update(update_params)
      redirect_to [ @license.licensable.school, @license.licensable, @license ], notice: "License was successfully updated."
    else
      if current_user.super_admin?
        @terms = Term.order(:start_date)
      else
        @terms = @school.terms.order(:start_date)
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @license.license_accesses.any?
      redirect_to [ @license.licensable.school, @license.licensable, @license ],
                  alert: "Cannot delete license with active student accesses."
    else
      licensable = @license.licensable
      school = licensable.school
      @license.destroy
      redirect_to school_term_path(school, licensable), notice: "License was successfully deleted."
    end
  end

  def purchase
    if current_user.student? && @license.seats_available? && !@license.expired?
      # Get payment method from params (default to credit_card for paid licenses)
      payment_method = params[:payment_method] || (@license.price > 0 ? "credit_card" : "free")

      # Validate payment method
      unless Payment.payment_methods.key?(payment_method)
        redirect_to [ @license.licensable.school, @license.licensable, @license ],
                    alert: "Invalid payment method selected."
        return
      end

      # Check if student already has access to this license
      existing_access = @license.license_accesses.find_by(student: current_user)
      if existing_access
        redirect_to [ @license.licensable.school, @license.licensable, @license ],
                    alert: "You already have access to this license."
        return
      end

      # Determine amount to pay
      amount_to_pay = @license.price || 0

      # For free licenses or waived payments, set amount to 0
      if %w[scholarship waived].include?(payment_method) || @license.price == 0
        amount_to_pay = 0
        payment_method = "waived" if @license.price == 0
      end

      ActiveRecord::Base.transaction do
        # Create payment record first (for all purchases, even free ones)
        payment = current_user.payments.build(
          amount: amount_to_pay,
          payment_method: payment_method,
          payable: @license
        )

        # Set payment status based on payment method and amount
        if amount_to_pay > 0 && !%w[cash scholarship waived].include?(payment_method)
          # Electronic payments start as pending
          payment.status = "pending"
        else
          # Free, cash, scholarship, or waived payments are immediately completed
          payment.status = "completed"
        end

        # Create payment breakdown
        payment.breakdown = {
          type: "license_purchase",
          license_id: @license.id,
          license_name: @license.name,
          licensable_type: @license.licensable_type,
          licensable_id: @license.licensable_id,
          licensable_name: @license.licensable.name,
          license_type: @license.license_type,
          amount: amount_to_pay,
          payment_method: payment_method,
          breakdown_date: Time.current.iso8601
        }

        unless payment.save
          redirect_to [ @license.licensable.school, @license.licensable, @license ],
                      alert: "Failed to process payment: #{payment.errors.full_messages.join(', ')}"
          return
        end

        # Create license access
        access = @license.license_accesses.build(
          student: current_user,
          purchased_at: Time.current
        )

        # Set license access status based on payment status
        access.status = payment.completed? ? "active" : "pending"

        # Set expiration if license has expiration
        if @license.expires_at.present?
          access.expires_at = @license.expires_at
        end

        unless access.save
          redirect_to [ @license.licensable.school, @license.licensable, @license ],
                      alert: "Failed to create license access: #{access.errors.full_messages.join(', ')}"
          return
        end

        # For pending payments, start background processing
        if payment.pending?
          LicensePaymentProcessingJob.perform_later(access.id, payment.id)

          redirect_to [ @license.licensable.school, @license.licensable, @license ],
                      notice: "License purchase initiated! Payment is being processed and you will be enrolled once payment is confirmed."
        else
          # For completed payments, show success message
          redirect_to [ @license.licensable.school, @license.licensable, @license ],
                      notice: "Successfully purchased license access! You are now enrolled."
        end
      end
    else
      error_message = if !current_user.student?
                       "Only students can purchase licenses."
      elsif !@license.seats_available?
                       "License has no available seats."
      elsif @license.expired?
                       "License has expired."
      else
                       "License is not available for purchase."
      end

      redirect_to [ @license.licensable.school, @license.licensable, @license ],
                  alert: error_message
    end
  end

  private

  def set_school
    if current_user.super_admin?
      # Super admin doesn't need a school - they can access all licenses
      @school = nil
    else
      @school = params[:school_id] ? School.find(params[:school_id]) : current_school
      redirect_to root_path unless @school == current_school
    end
  end

  def set_license
    if current_user.super_admin?
      # For super admin, find license directly without school context
      if params[:term_id]
        @term = Term.find(params[:term_id])
        @license = @term.licenses.find(params[:id])
      else
        @license = License.find(params[:id])
        @term = @license.licensable if @license.licensable_type == "Term"
      end
    else
      # For regular users, use school context
      if params[:term_id]
        @term = @school.terms.find(params[:term_id])
        @license = @term.licenses.find(params[:id])
      else
        @license = License.where(licensable_type: "Term")
                         .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                         .where(terms: { school_id: @school.id }).find(params[:id])
        @term = @license.licensable if @license.licensable_type == "Term"
      end
    end
  end

  def ensure_management_user
    redirect_to root_path, alert: "Access denied." unless current_user.management?
  end

  def license_params
    params.require(:license).permit(:name, :description, :price, :max_seats, :license_type, :expires_at, :term_id)
  end
end
