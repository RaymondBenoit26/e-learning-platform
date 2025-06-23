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
  def process_expired_licenses
    # Find all expired licenses with their related data
    expired_licenses = License.expired.includes(:license_accesses)

    expired_licenses.each do |license|
      Enrollment.where(payable: license, status: "active").update_all(status: "suspended")

      license.license_accesses.update_all(status: "expired")
    end
  end

  # Send email notifications for licenses expiring soon
  def notify_expiring_licenses
    expiring_soon = License.active.where("expires_at <= ? AND expires_at > ?",
                                        7.days.from_now, Time.current)
                           .includes(:students)

    expiring_soon.each do |license|
      license.students.each do |student|
        LicenseExpirationMailer.expiration_warning(student, license).deliver_later
      end
    end
  end
end
