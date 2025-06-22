class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # CanCanCan authorization (handled manually in each controller)

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone, :school_id, :user_type ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone, :bio ])
  end

  # Helper method to get current user's school
  def current_school
    @current_school ||= current_user&.school
  end
  helper_method :current_school

  # Helper method to check if current user can manage the school
  def can_manage_school?
    current_user&.management? || current_user&.super_admin?
  end
  helper_method :can_manage_school?

  # Helper method to check if current user is super admin
  def super_admin?
    current_user&.super_admin?
  end
  helper_method :super_admin?
end
