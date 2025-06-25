class LicensesController < ApplicationController
  before_action :set_school
  before_action :set_license, only: [ :show, :edit, :update, :destroy, :purchase ]
  before_action :set_terms, only: [ :new, :create, :edit, :update ]
  before_action :ensure_management_user, except: [ :index, :show, :purchase ]

  def index
    @q = build_ransack_query
    @licenses = @q.result(distinct: true).includes(license_includes).order(created_at: :desc)
    @license_stats = calculate_license_statistics if should_show_statistics?
  end

  def show
    @available_seats = @license.available_seats
    @enrolled_students = @license.students.includes(:school)
  end

  def new
    if params[:term_id]
      @licensable = @terms.find(params[:term_id])
    elsif params[:course_id]
      @licensable = Course.find(params[:course_id])
    end

    @license = @licensable.licenses.build if @licensable
    @license ||= License.new
  end

  def create
    if params[:license][:term_id].present?
      @licensable = @terms.find(params[:license][:term_id])
      @license = @licensable.licenses.build(license_params.except(:term_id, :course_id))
    elsif params[:license][:course_id].present?
      @licensable = Course.find(params[:license][:course_id])
      @license = @licensable.licenses.build(license_params.except(:term_id, :course_id))
    else
      redirect_to licenses_path, alert: "Please select a term or course for the license."
      return
    end

    if @license.save
      redirect_to [ @licensable.school, @licensable, @license ], notice: "License was successfully created."
    else
      @terms = @school.terms.order(:start_date) if @licensable.is_a?(Term)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Custom validation for max_seats
    if license_params[:max_seats].present? && license_params[:max_seats].to_i < @license.students.count
      @license.errors.add(:max_seats, "cannot be less than current usage (#{@license.students.count} seats)")
      render :edit, status: :unprocessable_entity
      return
    end

    # Handle term_id update by setting the polymorphic association
    update_params = license_params.except(:term_id)
    if license_params[:term_id].present?
      update_params[:licensable] = @terms.find(license_params[:term_id])
    end

    if @license.update(update_params)
      redirect_to [ @license.licensable.school, @license.licensable, @license ], notice: "License was successfully updated."
    else
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
    payment_method = params[:payment_method]

    result = LicensePurchaseService.new(
      license: @license,
      student: current_user,
      payment_method: payment_method
    ).call

    if result.success?
      payment = result.data[:payment]

      if payment.pending?
        redirect_to [ @license.licensable.school, @license.licensable, @license ],
                    notice: "License purchase initiated! Payment is being processed and you will be enrolled once payment is confirmed."
      else
        redirect_to [ @license.licensable.school, @license.licensable, @license ],
                    notice: "Successfully purchased license access! You are now enrolled."
      end
    else
      redirect_to [ @license.licensable.school, @license.licensable, @license ],
                  alert: result.error
    end
  end

  private

  def set_terms
    @terms = current_user.super_admin? ? Term.order(:start_date) : @school.terms.order(:start_date)
  end

  def set_school
    return if current_user.super_admin?

    @school = params[:school_id] ? School.find(params[:school_id]) : current_school
    redirect_to root_path unless @school == current_school
  end

  def set_license
    if params[:term_id]
      @term = @school.terms.find(params[:term_id])
      @license = @term.licenses.find(params[:id])
    elsif params[:course_id]
      @course = @school.courses.find(params[:course_id])
      @license = @course.licenses.find(params[:id])
    elsif current_user.super_admin?
      # For super admin, find license directly without school context
      @license = License.find(params[:id])
      @term = @license.licensable if @license.licensable_type == "Term"
      @course = @license.licensable if @license.licensable_type == "Course"
    else
      # Try to find license in terms first, then courses
      @license = License.where(licensable_type: "Term")
                        .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                        .where(terms: { school_id: @school.id }).find_by(id: params[:id])

      unless @license
        @license = License.where(licensable_type: "Course")
                          .joins("INNER JOIN courses ON courses.id = licenses.licensable_id")
                          .where(courses: { school_id: @school.id }).find(params[:id])
        @course = @license.licensable if @license.licensable_type == "Course"
      else
        @term = @license.licensable if @license.licensable_type == "Term"
      end
    end
  end

  def ensure_management_user
    redirect_to root_path, alert: "Access denied." unless current_user.management?
  end

  def license_params
    params.require(:license).permit(:name, :description, :price, :max_seats, :license_type, :expires_at, :term_id, :course_id)
  end

  def build_ransack_query
    base_scope = current_user.super_admin? ? License.all : License.by_school(@school)
    base_scope.ransack(params[:q])
  end

  def license_includes
    [ :license_accesses, :students, { licensable: :school } ]
  end

  def should_show_statistics?
    current_user.management? && !current_user.super_admin?
  end

  def calculate_license_statistics
    license_ids = @licenses.pluck(:id)

    {
      total_revenue: Payment.where(payable_type: "License", payable_id: license_ids).sum(:amount),
      most_popular_license: License.most_popular_for_school(@school)
    }
  end
end
