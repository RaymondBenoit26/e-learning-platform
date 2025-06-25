class EnrollmentsController < ApplicationController
  before_action :set_enrollment, only: [ :show, :destroy ]
  before_action :set_enrollable, only: [ :new, :create ]

  def index
    @enrollment_type = params[:type]&.downcase

    base_query = build_base_query_for_user
    base_query = apply_enrollment_type_filter(base_query) if @enrollment_type.present?
    base_query = apply_search_term_filter(base_query) if params[:search_term].present?

    @q = base_query.ransack(params[:q])
    @enrollments = @q.result(distinct: true).order("enrollments.created_at DESC").limit(50)

    set_enrollment_counts if current_user.student?
  end

  def new
    @enrollment = Enrollment.new
    @enrollment.enrollable = @enrollable
    @enrollment.student = current_user
  end

  def create
    @enrollment = Enrollment.new(enrollment_params)
    @enrollment.student = current_user
    @enrollment.enrollable = @enrollable

    if @enrollment.license_based? && params[:enrollment][:license_id].blank?
      @enrollment.errors.add(:license_id, "must be selected for license-based enrollment")
      render :new, status: :unprocessable_entity
      return
    end

    if @enrollment.direct_payment? && params[:enrollment][:payment_method].blank?
      @enrollment.errors.add(:payment_method, "must be selected for direct payment enrollment")
      render :new, status: :unprocessable_entity
      return
    end

    @enrollment.status = @enrollment.free? ? :active : :pending
    if @enrollment.save
      create_payment_for_enrollment(@enrollment) unless @enrollment.free?

      redirect_to @enrollment, notice: "Successfully enrolled!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
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
      # Check if management user has access to this enrollment (either course or term in their school)
      has_access = if @enrollment.course_enrollment?
        @enrollment.course.school == current_school
      elsif @enrollment.term_enrollment?
        @enrollment.term.school == current_school
      else
        false
      end
      redirect_to enrollments_path unless has_access
    end
  end

  def enrollment_params
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
    existing_access = license.license_accesses.find_by(student: current_user)
    if existing_access
      # If license access already exists and is active, link it to enrollment
      if existing_access.active?
        enrollment.update!(license_access: existing_access, status: :active)
        return
      else
        raise "You already have access to license '#{license.name}' but it's not active"
      end
    end

    # Create license access - this will automatically create the enrollment via callback
    # So we need to delete the manually created enrollment first
    enrollment.destroy

    # Create license access which will automatically create a proper enrollment
    license_access = license.license_accesses.build(student: current_user, status: :active)
    unless license_access.save
      raise "Failed to create license access: #{license_access.errors.full_messages.join(', ')}"
    end

    # Create payment record for the license (payment.payable = license, not enrollment)
    if license.price > 0
      payment = Payment.create!(
        student: current_user,
        payable: license,  # Payment is for the license, not enrollment
        amount: license.price,
        payment_method: :credit_card,
        status: :completed
      )

      # Create license purchase breakdown
      payment.create_license_breakdown(license)
    end
  end

  def create_direct_payment(enrollment)
    amount = if enrollment.term_enrollment?
      enrollment.enrollable.adjusted_total_course_price_for(current_user)
    else
      enrollment.enrollable.price
    end

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

    # Note: PaymentProcessingJob is automatically scheduled via Payment model's after_create callback
  end

  def build_base_query_for_user
    case current_user.user_type
    when "student"
      base_query = current_user.enrollments.includes(:student)
    when "instructor"
      course_ids = current_user.assigned_courses.pluck(:id)
      base_query = Enrollment.course_enrollments
                    .where(enrollable_id: course_ids)
                    .includes(:student)
    when "management"
      # Management users can see both course and term enrollments in their school
      base_query = Enrollment.joins(
        "LEFT JOIN courses ON courses.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Course'
         LEFT JOIN terms ON terms.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Term'"
      ).where(
        "(enrollments.enrollable_type = 'Course' AND courses.school_id = ?) OR
         (enrollments.enrollable_type = 'Term' AND terms.school_id = ?)",
        current_school.id, current_school.id
      ).includes(:student)
    end
    base_query
  end

  def apply_enrollment_type_filter(base_query)
    base_query.send("#{@enrollment_type}_enrollments")
  end

  def apply_search_term_filter(base_query)
    search_term = "%#{params[:search_term]}%"

    # Check if joins already exist (for management users)
    sql_string = base_query.to_sql
    already_has_joins = sql_string.include?("LEFT JOIN courses") && sql_string.include?("LEFT JOIN terms")

    if already_has_joins
      # Joins already exist, just add the where clause
      base_query.where("(enrollments.enrollable_type = 'Course' AND courses.name ILIKE ?) OR (enrollments.enrollable_type = 'Term' AND terms.name ILIKE ?)", search_term, search_term)
    else
      # Need to add the joins
      base_query.joins(
        "LEFT JOIN courses ON courses.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Course'
         LEFT JOIN terms ON terms.id = enrollments.enrollable_id AND enrollments.enrollable_type = 'Term'"
      ).where("(enrollments.enrollable_type = 'Course' AND courses.name ILIKE ?) OR (enrollments.enrollable_type = 'Term' AND terms.name ILIKE ?)", search_term, search_term)
    end
  end

  def set_enrollment_counts
    if current_user.student?
      @term_enrollment_count = current_user.term_enrollments.count
      @course_enrollment_count = current_user.course_enrollments.count
      @total_enrollment_count = @term_enrollment_count + @course_enrollment_count
    end
  end
end
