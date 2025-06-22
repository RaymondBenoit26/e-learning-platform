class EnrollmentsController < ApplicationController
  before_action :set_enrollment, only: [ :show, :destroy ]
  before_action :set_enrollable, only: [ :new, :create ]

    def index
    # Handle enrollment type filtering
    @enrollment_type = params[:type]&.downcase

    case current_user.user_type
    when "student"
      base_query = current_user.enrollments.includes(:student)

      # Filter by enrollment type if specified
      case @enrollment_type
      when "term"
        base_query = base_query.term_enrollments
      when "course"
        base_query = base_query.course_enrollments
      end

      # Apply custom search term filtering for polymorphic associations
      if params[:search_term].present?
        search_term = "%#{params[:search_term]}%"
        base_query = base_query.joins(
          "LEFT JOIN courses ON courses.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Course'
           LEFT JOIN terms ON terms.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Term'"
        ).where(
          "(enrollments.enrollable_type = 'Course' AND courses.name ILIKE ?) OR
           (enrollments.enrollable_type = 'Term' AND terms.name ILIKE ?)",
          search_term, search_term
        )
      end

      @q = base_query.ransack(params[:q])
    when "instructor"
      course_ids = current_user.assigned_courses.pluck(:id)
      base_query = Enrollment.course_enrollments
                    .where(enrollable_id: course_ids)
                    .includes(:student)

      # Apply custom search term filtering for courses only (instructor context)
      if params[:search_term].present?
        search_term = "%#{params[:search_term]}%"
        base_query = base_query.joins("INNER JOIN courses ON courses.id = enrollments.enrollable_id")
                              .where("courses.name ILIKE ?", search_term)
      end

      @q = base_query.ransack(params[:q])
    when "management"
      base_query = Enrollment.course_enrollments
                    .joins("INNER JOIN courses ON courses.id = enrollments.enrollable_id")
                    .where(courses: { school_id: current_school.id })
                    .includes(:student)

      # Apply custom search term filtering for courses only (management context)
      if params[:search_term].present?
        search_term = "%#{params[:search_term]}%"
        base_query = base_query.where("courses.name ILIKE ?", search_term)
      end

      @q = base_query.ransack(params[:q])
    end

    @enrollments = @q.result(distinct: true).order("enrollments.created_at DESC").limit(50)

    # Get enrollment counts for students
    if current_user.student?
      @term_enrollment_count = current_user.enrollments.term_enrollments.count
      @course_enrollment_count = current_user.enrollments.course_enrollments.count
      @total_enrollment_count = current_user.enrollments.count
    end
  end

  def new
    @enrollment = Enrollment.new
    @enrollment.enrollable = @enrollable
    @enrollment.student = current_user
  end

  def create
    Rails.logger.info "Enrollment create action called with params: #{params[:enrollment]}"
    Rails.logger.info "License params: #{license_params}"
    Rails.logger.info "Payment params: #{payment_params}"
    Rails.logger.info "Enrollment params: #{enrollment_params}"

    @enrollment = Enrollment.new(enrollment_params)
    @enrollment.student = current_user
    @enrollment.enrollable = @enrollable

    Rails.logger.info "Enrollment object created: #{@enrollment.attributes}"

    # Validate license selection for license-based enrollments
    if @enrollment.license_based? && params[:enrollment][:license_id].blank?
      Rails.logger.warn "License ID missing for license-based enrollment"
      @enrollment.errors.add(:license_id, "must be selected for license-based enrollment")
      render :new, status: :unprocessable_entity
      return
    end

    # Validate payment method for direct payment enrollments
    if @enrollment.direct_payment? && params[:enrollment][:payment_method].blank?
      Rails.logger.warn "Payment method missing for direct payment enrollment"
      @enrollment.errors.add(:payment_method, "must be selected for direct payment enrollment")
      render :new, status: :unprocessable_entity
      return
    end

    # Set initial status based on enrollment type
    if @enrollment.free?
      @enrollment.status = :active
    else
      @enrollment.status = :pending
    end

    Rails.logger.info "Attempting to save enrollment with status: #{@enrollment.status}"

    if @enrollment.save
      Rails.logger.info "Enrollment saved successfully with ID: #{@enrollment.id}"

      # Handle payment creation for non-free enrollments
      if !@enrollment.free?
        begin
          create_payment_for_enrollment(@enrollment)
          Rails.logger.info "Payment created successfully for enrollment #{@enrollment.id}"
        rescue => e
          Rails.logger.error "Payment creation failed: #{e.message}"
          @enrollment.errors.add(:base, "Payment creation failed: #{e.message}")
          render :new, status: :unprocessable_entity
          return
        end
      end

      redirect_to @enrollment, notice: "Successfully enrolled!"
    else
      Rails.logger.error "Enrollment validation failed: #{@enrollment.errors.full_messages}"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Show enrollment details including payment information
  end

  def destroy
    if can_manage_enrollment?
      @enrollment.destroy
      redirect_to enrollments_path, notice: "Enrollment was successfully removed."
    else
      redirect_to enrollments_path, alert: "You are not authorized to remove this enrollment."
    end
  end

  private

  def set_enrollable
    if params[:term_id]
      @enrollable = Term.find(params[:term_id])
    elsif params[:course_id]
      @enrollable = Course.find(params[:course_id])
    end
  end

  def set_enrollment
    @enrollment = Enrollment.find(params[:id])

    # Ensure user can access this enrollment
    case current_user.user_type
    when "student"
      redirect_to enrollments_path unless @enrollment.student == current_user
    when "instructor"
      course_ids = current_user.assigned_courses.pluck(:id)
      redirect_to enrollments_path unless @enrollment.course_enrollment? && course_ids.include?(@enrollment.enrollable_id)
    when "management"
      redirect_to enrollments_path unless @enrollment.course_enrollment? && @enrollment.course.school == current_school
    end
  end

  def enrollment_params
    # Remove license_id and payment_method from enrollment attributes since they're not model attributes
    # These will be handled separately in payment creation methods
    params.require(:enrollment).permit(:enrollment_type, :status)
  end

  def license_params
    params.require(:enrollment).permit(:license_id)
  end

  def payment_params
    params.require(:enrollment).permit(:payment_method)
  end

  def can_manage_enrollment?
    current_user.management? ||
    (current_user.instructor? && @enrollment.course_enrollment? && current_user.assigned_courses.include?(@enrollment.course)) ||
    (current_user.student? && @enrollment.student == current_user)
  end

  def create_payment_for_enrollment(enrollment)
    case enrollment.enrollment_type
    when "license_based"
      create_license_payment(enrollment)
    when "direct_payment", "course"
      create_direct_payment(enrollment)
    end
  end

  def create_license_payment(enrollment)
    # Get license_id from the enrollment parameters (not license_params)
    license_id = params[:enrollment][:license_id]

    if license_id.blank?
      raise "License ID is required for license-based enrollment"
    end

    license = License.find(license_id)

    # Check if license is still available
    unless license.seats_available?
      raise "License '#{license.name}' is no longer available"
    end

    # Check if user already has access to this license
    if license.license_accesses.exists?(student: current_user)
      raise "You already have access to license '#{license.name}'"
    end

    # Create license access
    license_access = license.license_accesses.build(student: current_user, status: :active)
    unless license_access.save
      raise "Failed to create license access: #{license_access.errors.full_messages.join(', ')}"
    end

    # Set the license as the payable for the enrollment
    enrollment.update(payable: license)

    # Create payment record for the license
    payment = Payment.create!(
      student: current_user,
      payable: enrollment,
      amount: license.price,
      payment_method: :scholarship, # License payments are typically pre-paid
      status: :completed
    )

    # Activate the enrollment immediately for license-based enrollments
    enrollment.update(status: :active)
  end

  def create_direct_payment(enrollment)
    # Calculate payment amount
    amount = if enrollment.term_enrollment?
      enrollment.enrollable.adjusted_total_course_price_for(current_user)
    else
      enrollment.enrollable.price
    end

    # Create pending payment
    payment = Payment.create!(
      student: current_user,
      payable: enrollment,
      amount: amount,
      payment_method: params[:enrollment][:payment_method] || :credit_card,
      status: :pending
    )

    # Create payment breakdown
    if enrollment.term_enrollment?
      payment.create_term_breakdown(enrollment.enrollable)
    elsif enrollment.course_enrollment?
      payment.create_course_breakdown(enrollment.enrollable)
    end

    # The payment processing job will handle the enrollment activation
  end
end
