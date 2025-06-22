# E-Learning Platform

A comprehensive learning management system built with Ruby on Rails that enables schools to manage courses, terms, licenses, and student enrollments with automated license expiration handling and multi-payment method support.

## 🚀 Features

### Core Functionality
- **Multi-School Support**: Each school can manage its own terms, courses, and licenses
- **User Management**: Students, instructors, management, and super admin roles with role-based access control
- **Term-Based Learning**: Organize courses into academic terms with start/end dates
- **Polymorphic License System**: Flexible licensing for both terms and courses with expiration dates and seat limits
- **Multi-Payment Integration**: Support for 9 different payment methods with realistic processing simulation
- **Course Management**: Chapters and course content organization with instructor assignments

### Advanced License Management
- **Multiple License Types**: Standard, Premium, Enterprise, and Lifetime licenses
- **Polymorphic Licensing**: Licenses can be attached to terms or individual courses
- **Automatic Expiration**: Licenses expire automatically with configurable dates
- **Seat Management**: Control how many students can use each license
- **Renewal System**: Students can renew expired licenses to continue learning
- **Email Notifications**: Automatic warnings before expiration and notifications when expired
- **License Access Tracking**: Complete audit trail of all license purchases and usage

### Payment System
- **Multiple Payment Methods**: 
  - Credit Card, Debit Card
  - Bank Transfer, PayPal, Stripe
  - Cash, Scholarship, Waived, Free
- **Realistic Payment Processing**: Background job simulation with different success rates per payment method
- **Payment Tracking**: Complete payment history with breakdown details
- **Status Management**: Pending, active, expired, cancelled license statuses
- **Automatic Enrollment**: Enrollments are automatically created when license purchases are successful

### Student Experience
- **License Purchase**: Students can purchase licenses with their preferred payment method
- **My Licenses Dashboard**: Comprehensive view of all purchased licenses with filtering and search
- **Term/Course Enrollment**: Students enroll in terms or courses using available licenses
- **Course Access**: Access to course materials based on valid license enrollment
- **Progress Tracking**: Monitor learning progress across terms and courses
- **License Renewal**: Easy renewal process for expired licenses
- **Payment History**: View all payment transactions and license purchases

### Administrative Features
- **Multi-Role Dashboard**: Customized dashboards for students, instructors, management, and super admins
- **User Management**: Create and manage students, instructors, and staff across schools
- **License Analytics**: Track license usage, revenue, and student engagement
- **Enrollment Management**: Comprehensive enrollment tracking with polymorphic support
- **Payment Processing**: Monitor payment status and processing with detailed breakdowns
- **Bulk Operations**: Manage multiple enrollments and licenses efficiently

## 🛠 Technology Stack

- **Backend**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL with optimized indexes
- **Authentication**: Devise with role-based authorization
- **Authorization**: CanCanCan for fine-grained permissions
- **Frontend**: Bootstrap 5, Font Awesome, Stimulus JS
- **Background Jobs**: Active Job with realistic payment processing simulation
- **Email**: Action Mailer with SMTP and HTML templates
- **Testing**: RSpec with comprehensive test coverage
- **Search**: Ransack for advanced filtering (with polymorphic association fixes)

## 📋 Prerequisites

- Ruby 3.3.0+
- Rails 8.0.2+
- PostgreSQL 12+
- Redis (for background jobs)
- Node.js (for asset compilation)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd e-learning-platform
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the server**
   ```bash
   rails server
   ```

5. **Access the application**
   - Navigate to `http://localhost:3000`
   - Login with seeded users or create new accounts

## 🗄 Database Schema

### Core Models

#### Users
- Students, instructors, management, and super admins
- Belongs to a school (except super admins)
- Has many enrollments, license accesses, and payments
- Polymorphic associations for flexible enrollment types

#### Schools
- Contains terms, courses, and users
- Each school operates independently
- Has address and contact information

#### Terms
- Academic periods with start/end dates and descriptions
- Contains courses and has many licenses (polymorphic)
- Students can enroll directly in terms or access via course enrollments

#### Courses
- Belong to terms and have instructor assignments
- Contain chapters and course content
- Can have direct licenses (polymorphic) or inherit from term licenses
- Students access courses through various enrollment paths

#### Licenses (Polymorphic)
- **Polymorphic Association**: Can belong to terms or courses via `licensable`
- **Types**: Standard, Premium, Enterprise, Lifetime
- **Pricing**: Configurable price and seat limits
- **Expiration**: Automatic expiration handling with background jobs
- **Access Control**: Controls student access to learning materials

#### License Accesses
- **Purchase Tracking**: Links students to purchased licenses
- **Status Management**: pending, active, expired, cancelled
- **Payment Integration**: Connected to payment records for full audit trail
- **Automatic Enrollment**: Creates enrollments when license becomes active

#### Payments (Polymorphic)
- **Multi-Method Support**: 9 different payment methods
- **Polymorphic Payable**: Can be linked to various payment sources
- **Breakdown Tracking**: Detailed payment breakdown with line items
- **Processing Status**: Realistic payment processing with background jobs

#### Enrollments (Polymorphic)
- **Flexible Enrollment**: Can enroll in terms or courses via `enrollable`
- **Status Tracking**: active, suspended, completed, cancelled
- **Payment Linkage**: Connected to payments via `payable` for source tracking
- **Automatic Creation**: Created automatically when license purchases succeed

## 🔐 License Purchase & Access System

### How It Works
1. **License Creation**: Admins create licenses for terms or courses with pricing and expiration
2. **Student Purchase**: Students select payment method and purchase licenses
3. **Payment Processing**: Background job processes payment with realistic delays and success rates
4. **Automatic Enrollment**: Successful payments automatically create enrollments
5. **Access Control**: Students can access materials only with valid active licenses
6. **Expiration Management**: Background jobs handle license expiration and access suspension
7. **Renewal Process**: Students can renew expired licenses to restore access

### Payment Processing Flow
```
Student Purchase → Payment Record Created → Background Job Processing → 
Payment Success → License Access Activated → Enrollment Created → Access Granted
```

### Payment Methods & Success Rates
- **Credit/Debit Cards**: 95% success rate, 2-5 second processing
- **Bank Transfer**: 98% success rate, 1-3 second processing  
- **PayPal/Stripe**: 97% success rate, 1-2 second processing
- **Cash/Free/Waived**: 100% success rate, instant processing

### Background Jobs
- **LicensePaymentProcessingJob**: Processes payments with realistic delays
- **LicenseExpirationJob**: Runs daily to process expired licenses
- **FixPendingEnrollmentsJob**: Handles enrollment cleanup tasks

## 🎯 Usage Examples

### Creating Polymorphic Licenses
```ruby
# Term license
term.licenses.create!(
  name: "Fall 2024 Access",
  price: 299.99,
  max_seats: 100,
  license_type: "standard",
  expires_at: term.end_date + 1.month
)

# Course license
course.licenses.create!(
  name: "Advanced Ruby Course",
  price: 99.99,
  max_seats: 50,
  license_type: "premium",
  expires_at: 6.months.from_now
)
```

### Student License Purchase
```ruby
# Student purchases with payment method
license_access = student.license_accesses.create!(
  license: license,
  payment_method: "credit_card",
  amount_paid: license.price,
  status: "pending"
)

# Payment processing job handles the rest
LicensePaymentProcessingJob.perform_later(license_access.id)
```

### Checking Student Access
```ruby
# Check if student has access to term
student.can_access_term?(term)

# Check if student has access to course
student.can_access_course?(course)

# Get all active license accesses
student.license_accesses.active
```

## 🔧 Configuration

### Background Job Setup
```ruby
# config/application.rb
config.active_job.queue_adapter = :async # or :sidekiq for production
```

### Payment Method Configuration
```ruby
# In LicenseAccess model
enum payment_method: {
  credit_card: 0,
  debit_card: 1, 
  bank_transfer: 2,
  paypal: 3,
  stripe: 4,
  cash: 5,
  scholarship: 6,
  waived: 7,
  free: 8
}
```

## 🧪 Testing

Run the comprehensive test suite:
```bash
bundle exec rspec
```

The test suite includes:
- **Model Tests**: Validations, associations, and business logic
- **Controller Tests**: Actions, authorization, and response handling
- **View Tests**: Rendering and user interface components
- **Job Tests**: Background job processing and error handling
- **Integration Tests**: End-to-end user workflows

### Test Coverage
- License purchase workflows
- Payment processing simulation
- Automatic enrollment creation
- Polymorphic association handling
- Role-based access control
- License expiration management

## 📊 Key Features Implemented

### ✅ Recent Enhancements
- **Multi-Payment Method Support**: 9 different payment options with realistic processing
- **Automatic Enrollment Creation**: No manual enrollment needed after license purchase
- **License Access Dashboard**: Students can view all their licenses with filtering
- **Polymorphic Association Fixes**: Resolved eager loading issues for better performance
- **Enhanced Payment Tracking**: Complete audit trail of all transactions
- **Improved Error Handling**: Better user feedback and error recovery
- **Background Job Processing**: Realistic payment processing with variable success rates

### 🔧 Technical Improvements
- **Database Optimization**: Proper indexing for payment and license queries
- **Polymorphic Architecture**: Clean separation of concerns with flexible associations
- **Role-Based Security**: Comprehensive authorization across all user types
- **Performance Optimization**: Efficient queries without N+1 problems
- **Error Recovery**: Graceful handling of payment failures and edge cases

## 🚨 Known Issues & Fixes Applied

### ✅ Fixed Issues
- **Polymorphic Eager Loading**: Resolved "Cannot eagerly load polymorphic association" errors
- **License Form Errors**: Fixed undefined method `term_id` in license forms
- **Search Functionality**: Implemented custom search for polymorphic associations
- **Payment Method Validation**: Proper enum handling and validation
- **Database Constraints**: Corrected column references and associations

### 🔍 Monitoring & Debugging
- Comprehensive error logging for payment processing
- Background job status tracking
- License expiration monitoring
- Payment success rate analytics

## 🔒 Security Considerations

- **Role-Based Access Control**: Strict authorization for all user actions
- **Payment Security**: No sensitive payment data stored locally
- **License Validation**: Server-side license checking prevents unauthorized access
- **Session Management**: Secure user authentication with Devise
- **Data Validation**: Comprehensive input validation and sanitization

## 🚀 Deployment

### Production Checklist
- [ ] Configure production database with proper indexes
- [ ] Set up background job processing (Sidekiq recommended)
- [ ] Configure email delivery for notifications
- [ ] Set up SSL certificate for secure payments
- [ ] Configure monitoring and error tracking
- [ ] Set up automated backups
- [ ] Configure payment processor integration
- [ ] Set up log rotation and monitoring

### Recommended Architecture
- **Application Server**: Puma with multiple workers
- **Background Jobs**: Sidekiq with Redis
- **Database**: PostgreSQL with read replicas
- **Caching**: Redis for session and fragment caching
- **Email**: SMTP service or transactional email provider

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with proper tests
4. Run the test suite (`bundle exec rspec`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines
- Follow Rails conventions and best practices
- Write comprehensive tests for new features
- Update documentation for API changes
- Use semantic commit messages
- Ensure backward compatibility

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support & Documentation

For support and questions:
- **Issues**: Create an issue in the repository
- **Documentation**: Check `/docs` directory and inline code comments
- **Examples**: Review test files for usage examples
- **Models**: See `MODELS_README.md` for detailed model documentation
- **License System**: See `LICENSE_EXPIRATION_SYSTEM.md` for expiration details

### Additional Resources
- **API Documentation**: Available in controller comments
- **Database Schema**: Run `rails db:schema:dump` for current schema
- **Background Jobs**: Check job classes for processing details
- **Payment Integration**: See payment processing job for implementation details

---

**Built with ❤️ for comprehensive education management**

*Last Updated: June 2025 - Version 2.0 with Enhanced Payment System*
