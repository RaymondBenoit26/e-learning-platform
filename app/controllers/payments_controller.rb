class PaymentsController < ApplicationController
  before_action :set_school
  before_action :set_payment, only: [ :show ]
  before_action :set_course, only: [ :new, :create ]

  def index
    case current_user.user_type
    when "super_admin"
      @q = Payment.includes(:student, :payable).ransack(params[:q])
    when "management"
      @q = Payment.joins(student: :school).where(users: { school_id: current_user.school_id }).includes(:student, :payable).ransack(params[:q])
    when "instructor"
      course_ids = current_user.assigned_courses.pluck(:id)
      @q = Payment.joins("JOIN enrollments ON payments.payable_type = 'Enrollment' AND payments.payable_id = enrollments.id")
                  .where(enrollments: { enrollable_type: "Course", enrollable_id: course_ids })
                  .includes(:student, :payable)
                  .ransack(params[:q])
    else # student
      @q = current_user.payments.includes(:payable).ransack(params[:q])
    end
    @payments = @q.result(distinct: true).order("payments.created_at DESC").limit(50)
  end

  def new
    # Check if user is already enrolled
    if current_user.courses.include?(@course)
      redirect_to @course, alert: "You are already enrolled in this course."
      return
    end

    # Create a pending enrollment
    @enrollment = @course.enrollments.build(student: current_user, status: :pending)

    if @enrollment.save
      @payment = Payment.new(
        student: current_user,
        payable: @enrollment,
        amount: @course.price,
        payment_method: :credit_card,
        status: :pending
      )
    else
      redirect_to @course, alert: "Failed to create enrollment."
    end
  end

  def create
    # Find the pending enrollment
    @enrollment = @course.enrollments.find_by(student: current_user, status: :pending)

    unless @enrollment
      redirect_to @course, alert: "No pending enrollment found."
      return
    end

    # Create the payment
    @payment = Payment.new(payment_params)
    @payment.student = current_user
    @payment.payable = @enrollment
    @payment.amount = @course.price
    @payment.status = :pending

    if @payment.save
      # Create payment breakdown
      @payment.create_course_breakdown(@course)

      redirect_to @payment, notice: "Payment created successfully. It will be processed automatically."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Ensure user can access this payment
    case current_user.user_type
    when "student"
      redirect_to payments_path unless @payment.student == current_user
    when "instructor"
      course_ids = current_user.assigned_courses.pluck(:id)
      unless @payment.payable_type == "Enrollment" && @payment.payable.enrollable_type == "Course" && course_ids.include?(@payment.payable.enrollable_id)
        redirect_to payments_path
      end
    when "management"
      redirect_to payments_path unless @payment.student.school == @school
    end
  end

  private

  def set_school
    @school = current_school
  end

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def set_course
    @course = @school.courses.find(params[:course_id])
  end

  def payment_params
    params.require(:payment).permit(:payment_method)
  end
end
