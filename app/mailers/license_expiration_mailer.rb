# LicenseExpirationMailer handles email notifications for license expiration events
# Sends two types of emails:
# 1. Warning emails before license expiration (7 days notice)
# 2. Expiration notification emails when license expires
#
# These emails help students stay informed about their license status
# and encourage timely renewals to maintain uninterrupted access
class LicenseExpirationMailer < ApplicationMailer
  # Send warning email to student when license is expiring soon
  # This gives students advance notice to renew their license
  #
  # @param student [User] the student receiving the warning
  # @param license [License] the license that's expiring
  def expiration_warning(student, license)
    @student = student
    @license = license
    @term = license.term

    # Calculate days until expiration for the email content
    @days_until_expiry = ((license.expires_at - Time.current) / 1.day).round

    # Send email with subject line indicating urgency
    mail(
      to: @student.email,
      subject: "Your license for #{@term.name} expires in #{@days_until_expiry} days"
    )
  end

  # Send notification email when license has expired
  # This informs students that their access has been suspended
  # and provides renewal options
  #
  # @param student [User] the student whose license expired
  # @param license [License] the expired license
  def license_expired(student, license)
    @student = student
    @license = license
    @term = license.term

    # Send email with clear subject about expiration
    mail(
      to: @student.email,
      subject: "Your license for #{@term.name} has expired"
    )
  end
end
