# LicenseExpirationJob handles automatic license expiration processing
# This job runs daily to:
# 1. Process expired licenses and suspend related enrollments
# 2. Send email notifications for licenses expiring soon
#
# This ensures that students lose access when their licenses expire
# and provides timely warnings before expiration
class LicenseExpirationJob < ApplicationJob
  queue_as :default

  def perform
    process_expired_licenses
    notify_expiring_licenses
  end

  private

  # Process all expired licenses and suspend related enrollments
  # This is the core functionality that enforces license expiration
  def process_expired_licenses
    # Find all expired licenses with their related data
    expired_licenses = License.expired.includes(:license_accesses)

    expired_licenses.each do |license|
      # Suspend all active enrollments for this expired license
      # This immediately revokes access to courses/terms
      Enrollment.where(payable: license, status: "active").update_all(status: "suspended")

      # Update license access status to expired
      # This prevents further purchases of the same license
      license.license_accesses.update_all(status: "expired")

      # Log the expiration for monitoring and debugging
      Rails.logger.info "License #{license.id} (#{license.name}) expired. Suspended #{Enrollment.where(payable: license).count} enrollments."
    end
  end

  # Send email notifications for licenses expiring soon
  # This gives students advance warning to renew their licenses
  def notify_expiring_licenses
    # Find licenses expiring in the next 7 days
    # This provides enough time for students to renew
    expiring_soon = License.active.where("expires_at <= ? AND expires_at > ?",
                                        7.days.from_now, Time.current)
                           .includes(:students)

    expiring_soon.each do |license|
      # Send warning email to each student with this license
      license.students.each do |student|
        # Use deliver_later to avoid blocking the job
        LicenseExpirationMailer.expiration_warning(student, license).deliver_later
      end
    end
  end
end
