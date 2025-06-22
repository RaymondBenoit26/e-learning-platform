# License Expiration System Documentation

## Overview

The e-learning platform implements a comprehensive license expiration system that automatically manages student access based on license validity. This system ensures that students lose access when their licenses expire and provides mechanisms for renewal.

## System Architecture

### Core Components

1. **License Model** (`app/models/license.rb`)
   - Manages license types (standard, premium, enterprise, lifetime)
   - Tracks expiration dates and seat limits
   - Provides scopes for active/expired filtering

2. **TermEnrollment Model** (`app/models/term_enrollment.rb`)
   - Links students to terms via licenses
   - Tracks enrollment status (active, suspended, completed, cancelled)
   - Automatically suspended when license expires

3. **User Model** (`app/models/user.rb`)
   - Provides access control methods
   - Checks license validity for term/course access
   - Manages license relationships

4. **LicenseExpirationJob** (`app/jobs/license_expiration_job.rb`)
   - Background job that processes expired licenses
   - Sends email notifications
   - Runs daily to maintain system integrity

5. **LicenseRenewalsController** (`app/controllers/license_renewals_controller.rb`)
   - Handles license renewal process
   - Provides UI for students to renew expired licenses

6. **LicenseExpirationMailer** (`app/mailers/license_expiration_mailer.rb`)
   - Sends expiration warnings and notifications
   - Encourages timely renewals

## How It Works

### 1. License Creation
```ruby
# Admin creates a license with expiration date
license = term.licenses.create!(
  name: "Fall 2024 Standard",
  price: 299.99,
  max_seats: 100,
  license_type: "standard",
  expires_at: term.end_date + 1.month
)
```

### 2. Student Purchase
```ruby
# Student purchases license and enrolls in term
enrollment = term.term_enrollments.create!(
  student: student,
  license: license,
  status: "active"
)
```

### 3. Access Control
```ruby
# System checks if student can access term
def can_access_term?(term)
  enrollment = term_enrollments.find_by(term: term)
  enrollment&.has_valid_access?
end

# System checks if student can access course
def can_access_course?(course)
  return false unless can_access_term?(course.term)
  enrollments.where(course: course, status: 'active').exists?
end
```

### 4. Automatic Expiration Processing
The `LicenseExpirationJob` runs daily and:

1. **Finds expired licenses**
   ```ruby
   expired_licenses = License.expired.includes(:term_enrollments, :license_accesses)
   ```

2. **Suspends enrollments**
   ```ruby
   license.term_enrollments.where(status: 'active').update_all(status: 'suspended')
   ```

3. **Updates license access status**
   ```ruby
   license.license_accesses.update_all(status: 'expired')
   ```

4. **Sends notifications**
   ```ruby
   LicenseExpirationMailer.expiration_warning(student, license).deliver_later
   ```

### 5. License Renewal
When a license expires, students can renew:

1. **View expired enrollments**
   ```ruby
   @expired_enrollments = current_user.term_enrollments.with_expired_license
   ```

2. **Select renewal option**
   ```ruby
   @renewal_options = @term_enrollment.renewal_options
   ```

3. **Process renewal**
   ```ruby
   @term_enrollment.update!(license: new_license, status: "active")
   ```

## Key Features

### License Types
- **Standard**: Basic access with standard expiration
- **Premium**: Enhanced features with longer access
- **Enterprise**: Advanced features for organizations
- **Lifetime**: No expiration - permanent access

### Expiration Handling
- **Automatic suspension**: Enrollments suspended when license expires
- **Email notifications**: Warnings 7 days before expiration
- **Renewal process**: Easy renewal to restore access
- **Access control**: Course access tied to valid licenses

### Seat Management
- **Seat limits**: Each license has maximum number of users
- **Availability checking**: Prevents over-subscription
- **Usage tracking**: Monitor license utilization

## Database Schema

### Key Tables
```sql
-- Licenses table
licenses (
  id, name, description, price, max_seats, 
  expires_at, license_type, term_id
)

-- Term enrollments table
term_enrollments (
  id, student_id, term_id, license_id, 
  status, payable_type, payable_id
)

-- License accesses table
license_accesses (
  id, license_id, student_id, status
)

-- Payments table
payments (
  id, student_id, amount, payment_method, 
  status, payable_type, payable_id
)
```

## API Endpoints

### License Renewal
```
GET  /license_renewals              # List expired/expiring enrollments
GET  /license_renewals/:id          # Show renewal options
POST /license_renewals/:id/renew    # Process renewal
```

### Term Enrollments
```
GET  /term_enrollments              # List user enrollments
GET  /term_enrollments/:id          # Show enrollment details
POST /term_enrollments              # Create new enrollment
DELETE /term_enrollments/:id        # Cancel enrollment
```

## Email Templates

### Expiration Warning
- Sent 7 days before license expires
- Includes license details and renewal options
- Encourages timely renewal

### License Expired
- Sent when license expires
- Explains access suspension
- Provides renewal instructions

## Monitoring and Logging

### Key Metrics
- License expiration rates
- Renewal conversion rates
- Revenue per license type
- Student engagement after renewal

### Logs
```ruby
# License expiration processing
Rails.logger.info "License #{license.id} (#{license.name}) expired. Suspended #{license.term_enrollments.count} enrollments."

# Email delivery status
LicenseExpirationMailer.expiration_warning(student, license).deliver_later
```

## Configuration

### Background Job Setup
```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq

# Schedule daily job
# config/recurring.yml or use cron/sidekiq-scheduler
```

### Email Configuration
```yaml
# config/application.yml
SMTP_HOST: smtp.gmail.com
SMTP_PORT: 587
SMTP_USERNAME: your-email@gmail.com
SMTP_PASSWORD: your-app-password
```

## Best Practices

### For Developers
1. Always check license validity before granting access
2. Use the provided scopes for filtering expired licenses
3. Handle renewal failures gracefully
4. Log all expiration events for monitoring

### For Administrators
1. Set appropriate expiration dates for licenses
2. Monitor renewal rates and adjust pricing
3. Review expired licenses regularly
4. Configure email notifications properly

### For Students
1. Monitor license expiration dates
2. Renew licenses before expiration
3. Contact support for renewal issues
4. Consider lifetime licenses for long-term access

## Troubleshooting

### Common Issues

1. **Students can't access courses after renewal**
   - Check if enrollment status was updated to "active"
   - Verify license is not expired
   - Ensure course enrollment exists

2. **Email notifications not sent**
   - Check SMTP configuration
   - Verify background job is running
   - Check job queue status

3. **License expiration not processed**
   - Verify LicenseExpirationJob is scheduled
   - Check job logs for errors
   - Ensure license has valid expiration date

### Debug Commands
```ruby
# Check expired licenses
License.expired.count

# Check suspended enrollments
TermEnrollment.where(status: 'suspended').count

# Check expiring licenses
License.active.where("expires_at <= ?", 7.days.from_now).count

# Test email delivery
LicenseExpirationMailer.expiration_warning(student, license).deliver_now
```

## Future Enhancements

1. **Automatic Renewal**: Allow students to set up automatic renewals
2. **Payment Integration**: Integrate with payment processors
3. **Analytics Dashboard**: Detailed license usage analytics
4. **Bulk Operations**: Admin tools for bulk license management
5. **Mobile Notifications**: Push notifications for expiration warnings

---

This system ensures that the e-learning platform maintains proper access control while providing a smooth experience for students to manage their licenses and continue their learning journey. 