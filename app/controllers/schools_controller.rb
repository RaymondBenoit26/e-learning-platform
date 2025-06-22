class SchoolsController < ApplicationController
  before_action :set_school, only: [ :show, :edit, :update ]
  before_action :ensure_management_user

  def index
    redirect_to current_school
  end

  def show
    @school = current_school
    @total_students = @school.students.count
    @total_instructors = @school.instructors.count
    @total_courses = @school.courses.count
                @recent_enrollments = Enrollment.course_enrollments
                                     .joins("INNER JOIN courses ON courses.id = enrollments.enrollable_id")
                                     .where(courses: { school_id: @school.id })
                                     .includes(:student)
                                    .order(created_at: :desc)
                                    .limit(5)
  end

  def edit
    @school = current_school
  end

  def update
    @school = current_school
    if @school.update(school_params)
      redirect_to @school, notice: "School was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_school
    @school = School.find(params[:id])
    # Ensure user can only access their own school
    redirect_to current_school unless @school == current_school
  end

  def ensure_management_user
    redirect_to root_path, alert: "Access denied." unless current_user.management?
  end

  def school_params
    params.require(:school).permit(:name, :domain, :address, :phone, :email)
  end
end
