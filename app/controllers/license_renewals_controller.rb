# LicenseRenewalsController handles the license renewal process for students
# When a student's license expires, they can renew it to restore access to their term
# This controller provides the interface for viewing expired licenses and processing renewals
class LicenseRenewalsController < ApplicationController
  before_action :set_school
  before_action :set_term_enrollment, only: [ :show, :renew ]
  before_action :ensure_student_user

  # Display all expired and expiring enrollments for the current student
  # This gives students an overview of licenses that need attention
  def index
    # Get enrollments with expired licenses - these need immediate renewal
    @expired_enrollments = current_user.term_enrollments.with_expired_license.includes(:term, :license)

    # Get enrollments with licenses expiring soon - these need attention
    @expiring_enrollments = current_user.term_enrollments.joins(:license)
                                      .where("licenses.expires_at <= ? AND licenses.expires_at > ?",
                                            7.days.from_now, Time.current)
                                      .includes(:term, :license)
  end

  # Show renewal options for a specific term enrollment
  # Displays available licenses that can be used to renew the expired enrollment
  def show
    # Get available renewal options (same license type or lifetime)
    @renewal_options = @term_enrollment.renewal_options
    @current_license = @term_enrollment.license
  end

  # Process the license renewal for a term enrollment
  # Creates a new license access and updates the enrollment with the new license
  def renew
    new_license = License.find(params[:license_id])

    # Validate that the selected license is available for renewal
    # This prevents unauthorized license upgrades or invalid selections
    unless @term_enrollment.renewal_options.include?(new_license)
      redirect_to license_renewal_path(@term_enrollment),
                  alert: "Selected license is not available for renewal."
      return
    end

    # Create new license access for the student
    # This establishes the student's right to use the new license
    access = new_license.license_accesses.build(student: current_user, status: "active")

    if access.save
      # Update the term enrollment with the new license and restore active status
      # This immediately restores the student's access to term courses
      @term_enrollment.update!(license: new_license, status: "active")

      # Create payment record if the new license has a cost
      # This tracks the revenue from license renewals
      if new_license.price > 0
        payment = current_user.payments.create!(
          amount: new_license.price,
          payment_method: "credit_card",
          status: "completed",
          payable: @term_enrollment
        )
      end

      # Redirect with success message
      redirect_to term_enrollments_path,
                  notice: "Successfully renewed license for #{@term_enrollment.term.name}!"
    else
      # Handle renewal failure
      redirect_to license_renewal_path(@term_enrollment),
                  alert: "Failed to renew license. Please try again."
    end
  end

  private

  # Set the current school context for the request
  def set_school
    @school = current_school
  end

  # Find the specific term enrollment for the current student
  # Ensures students can only renew their own enrollments
  def set_term_enrollment
    @term_enrollment = current_user.term_enrollments.find(params[:id])
  end

  # Ensure only students can access license renewal functionality
  # Instructors and admins don't need to renew licenses
  def ensure_student_user
    redirect_to root_path, alert: "Access denied." unless current_user.student?
  end
end
