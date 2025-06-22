class SuperAdmin::SchoolsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_super_admin
  before_action :set_school, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = School.ransack(params[:q])
    @schools = @q.result(distinct: true)
                 .includes(:users, :terms, :courses)
                 .order(created_at: :desc)

    # Statistics
    @total_schools = @schools.count
    @total_students = User.joins(:school).where(user_type: "student").count
    @total_instructors = User.joins(:school).where(user_type: "instructor").count
    @total_courses = Course.count
    @recent_schools = @schools.limit(5)
  end

  def show
    @students_count = @school.users.students.count
    @instructors_count = @school.users.instructors.count
    @management_count = @school.users.management.count
    @terms_count = @school.terms.count
    @courses_count = @school.courses.count
    @recent_enrollments = Enrollment.joins(:course)
                                  .where(courses: { school_id: @school.id })
                                  .includes(:student, :course)
                                  .order(created_at: :desc)
                                  .limit(10)
  end

  def new
    @school = School.new
  end

  def create
    @school = School.new(school_params)

    if @school.save
      # Create a default management user for the school
      if params[:school][:admin_email].present?
        admin_user = @school.users.create!(
          email: params[:school][:admin_email],
          password: params[:school][:admin_password] || "temppassword123",
          first_name: params[:school][:admin_first_name] || "Admin",
          last_name: params[:school][:admin_last_name] || "User",
          user_type: "management"
        )
      end

      redirect_to super_admin_school_path(@school), notice: "School was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @school.update(school_params)
      redirect_to super_admin_school_path(@school), notice: "School was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    school_name = @school.name

    if @school.users.any? || @school.courses.any?
      redirect_to super_admin_school_path(@school),
                  alert: "Cannot delete school with existing users or courses. Please transfer or remove them first."
    else
      @school.destroy
      redirect_to super_admin_schools_path, notice: "School '#{school_name}' was successfully deleted."
    end
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def ensure_super_admin
    unless current_user&.super_admin?
      redirect_to root_path, alert: "Access denied. Super admin access required."
    end
  end

  def school_params
    params.require(:school).permit(:name, :address, :city, :state, :zip_code, :phone, :email, :website)
  end
end
