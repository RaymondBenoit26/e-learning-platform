class ProfilesController < ApplicationController
  before_action :set_user

  def show
    case @user.user_type
    when "student"
      @enrolled_courses = @user.courses.includes(:instructors, :chapters)
      @recent_enrollments = @user.enrollments.includes(:course).order("enrollments.created_at DESC").limit(5)
    when "instructor"
      @assigned_courses = @user.assigned_courses.includes(:students, :chapters)
      @total_students = @assigned_courses.joins(:students).distinct.count
    when "management"
      @school_stats = {
        students: current_school.students.count,
        instructors: current_school.instructors.count,
        courses: current_school.courses.count
      }
    end
  end

  def edit
  end

  def update
    # Remove password fields if empty
    if user_params[:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params.except(:password, :password_confirmation))
      redirect_to profile_path, notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :bio, :password, :password_confirmation)
  end
end
