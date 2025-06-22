class UsersController < ApplicationController
  before_action :set_school
  before_action :set_user, only: [ :edit, :update, :destroy, :toggle_status ]
  before_action :ensure_management_user

  def index
    @q = @school.users.includes(:enrollments, :assigned_courses).ransack(params[:q])
    @users = @q.result(distinct: true).order(:first_name, :last_name)
  end

  def new
    @user = @school.users.build
  end

  def create
    @user = @school.users.build(user_params)
    @user.password = generate_temp_password
    @user.password_confirmation = @user.password

    if @user.save
      # In a real app, you'd send an email with login credentials
      redirect_to school_users_path(@school),
                  notice: "User created successfully. Temporary password: #{@user.password}"
    else
      render :new, status: :unprocessable_entity
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
      redirect_to school_users_path(@school), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to school_users_path(@school), alert: "You cannot delete yourself."
    elsif @user.destroy
      redirect_to school_users_path(@school), notice: "User was successfully deleted."
    else
      redirect_to school_users_path(@school), alert: "Failed to delete user."
    end
  end

  def toggle_status
    # This could be used to activate/deactivate users
    # For now, we'll just redirect back
    redirect_to school_users_path(@school), notice: "User status updated."
  end

  private

  def set_school
    @school = School.find(params[:school_id])
    # Ensure user can only access their own school
    redirect_to root_path unless @school == current_school
  end

  def set_user
    @user = @school.users.find(params[:id])
  end

  def ensure_management_user
    redirect_to root_path, alert: "Access denied." unless current_user.management?
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :bio, :user_type, :password, :password_confirmation)
  end

  def generate_temp_password
    SecureRandom.hex(8)
  end
end
