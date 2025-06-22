# E-Learning Platform - Models Documentation

## Overview
This Rails 8 application implements a **multi-tenant learning platform** for schools with support for students, instructors, enrollments, licensing, payments, and course content management.

## Tech Stack
- Ruby on Rails 8
- PostgreSQL
- Devise (authentication)
- CanCanCan (authorization)
- Bootstrap (styling)
- ActiveStorage (file uploads)
- SimpleForm (forms)

## Model Architecture

### Core Models

#### 1. School (Multi-tenant Root)
```ruby
class School < ApplicationRecord
  has_many :terms, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :users, dependent: :destroy
  
  # Scoped associations for different user types
  has_many :students, -> { where(user_type: :student) }, class_name: 'User'
  has_many :instructors, -> { where(user_type: :instructor) }, class_name: 'User'
  has_many :management_users, -> { where(user_type: :management) }, class_name: 'User'
end
```
**Attributes:** `name`, `domain`, `address`, `phone`, `email`

#### 2. Term
```ruby
class Term < ApplicationRecord
  belongs_to :school
  has_many :courses, dependent: :destroy
  has_many :licenses, dependent: :destroy
end
```
**Attributes:** `name`, `start_date`, `end_date`

#### 3. Course
```ruby
class Course < ApplicationRecord
  belongs_to :school
  belongs_to :term, optional: true
  
  has_many :chapters, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :course_assignments, dependent: :destroy
  has_many :instructors, through: :course_assignments
end
```
**Attributes:** `name`, `description`

### Content Management

#### 4. Chapter
```ruby
class Chapter < ApplicationRecord
  belongs_to :course
  has_many :course_contents, dependent: :destroy
end
```
**Attributes:** `title`, `description`, `order`

#### 5. CourseContent
```ruby
class CourseContent < ApplicationRecord
  belongs_to :course
  belongs_to :chapter, optional: true
  
  has_one_attached :file
end
```
**Attributes:** `title`, `description`, `content_type`
**File Uploads:** Supports videos, PDFs, documents via ActiveStorage

### User Management

#### 6. User (Unified User Model with Devise Authentication)
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  belongs_to :school
  
  # User type enum
  enum :user_type, {
    student: 0,
    instructor: 1,
    management: 2
  }
  
  # Student associations
  has_many :enrollments, dependent: :destroy, foreign_key: 'student_id'
  has_many :courses, through: :enrollments
  has_many :payments, dependent: :destroy, foreign_key: 'student_id'
  has_many :license_accesses, dependent: :destroy, foreign_key: 'student_id'
  
  # Instructor associations
  has_many :course_assignments, dependent: :destroy, foreign_key: 'instructor_id'
  has_many :assigned_courses, through: :course_assignments, source: :course
  
  # Scopes for different user types
  scope :students, -> { where(user_type: :student) }
  scope :instructors, -> { where(user_type: :instructor) }
  scope :management, -> { where(user_type: :management) }
end
```
**Attributes:** `email`, `first_name`, `last_name`, `phone`, `bio`, `user_type` (enum)
**Authentication:** Handled by Devise
**User Types:** `student`, `instructor`, `management`

#### 7. CourseAssignment (Join Table)
```ruby
class CourseAssignment < ApplicationRecord
  belongs_to :instructor, class_name: 'User'
  belongs_to :course
end
```
**Attributes:** `role` (e.g., "primary", "assistant")

### Enrollment & Payment System

#### 9. Enrollment (Polymorphic)
```ruby
class Enrollment < ApplicationRecord
  belongs_to :student
  belongs_to :course
  belongs_to :payable, polymorphic: true
end
```
**Attributes:** `status`
**Polymorphic Association:** Can point to `Payment` or `LicenseAccess`

#### 10. Payment (Polymorphic)
```ruby
class Payment < ApplicationRecord
  belongs_to :student
  belongs_to :payable, polymorphic: true
end
```
**Attributes:** `amount`, `payment_method`, `status`
**Polymorphic Association:** Can reference `Enrollment` or `Term`

### Licensing System

#### 11. License
```ruby
class License < ApplicationRecord
  belongs_to :term
  
  has_many :license_accesses, dependent: :destroy
  has_many :students, through: :license_accesses
end
```
**Attributes:** `name`, `description`, `price`, `max_seats`, `valid_until`

#### 12. LicenseAccess (Join Table)
```ruby
class LicenseAccess < ApplicationRecord
  belongs_to :license
  belongs_to :student
end
```
**Attributes:** `status`

## Authorization (CanCanCan)

### Ability Model
```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    case user.user_type
    when 'management'
      can :manage, :all
    when 'instructor'
      can :read, Course, course_assignments: { instructor_id: user.id }
      can :manage, Course, course_assignments: { instructor_id: user.id }
      can :manage, Chapter, course: { course_assignments: { instructor_id: user.id } }
      can :manage, CourseContent, course: { course_assignments: { instructor_id: user.id } }
    when 'student'
      can :read, Course, enrollments: { student_id: user.id }
      can :read, Chapter, course: { enrollments: { student_id: user.id } }
      can :read, CourseContent, course: { enrollments: { student_id: user.id } }
    end
  end
end
```

## Database Schema

### Key Features
- **Multi-tenancy:** All models scope to `School`
- **Polymorphic Associations:** Flexible payment and enrollment system
- **Join Tables:** Proper many-to-many relationships
- **Optional References:** Courses can exist without terms, content without chapters
- **Foreign Keys:** All relationships have proper constraints
- **Indexes:** Performance optimization on key lookups

### Sample Data Created
- 1 School: "Tech University"
- 1 Term: "Fall 2025"
- 5 Users total:
  - 2 Students: Alice Johnson, Bob Wilson
  - 2 Instructors: John Smith, Jane Doe
  - 1 Management: Admin User
- 2 Courses: Ruby on Rails Development, Database Design
- 2 Enrollments: Via license access and direct payment
- 1 License: Full Access License
- Course content with chapters and materials

## Usage Examples

### Working with User Types
```ruby
# Find users by type using enum scopes
students = User.students
instructors = User.instructors
management = User.management

# Create a new student
student = User.create!(
  school: school,
  email: "newstudent@example.com",
  password: "password123",
  first_name: "New",
  last_name: "Student",
  user_type: :student
)

# Check user type
user.student?     # returns true/false
user.instructor?  # returns true/false
user.management?  # returns true/false
user.admin?       # alias for management?

# User type as string
user.user_type    # returns "student", "instructor", or "management"
```

### Enrollment via License
```ruby
# Student enrolled through license access
student = User.students.find_by(email: "alice@student.techuniv.edu")
license_access = LicenseAccess.find_by(student: student)
enrollment = Enrollment.create!(
  student: student,
  course: course,
  payable: license_access,
  status: "active"
)
```

### Enrollment via Direct Payment
```ruby
# Student enrolled through direct payment
payment = Payment.create!(
  student: student,
  amount: 299.99,
  payment_method: "credit_card",
  status: "completed",
  payable: course
)

enrollment = Enrollment.create!(
  student: student,
  course: course,
  payable: payment,
  status: "active"
)
```

### Dashboard Metrics
```ruby
# Number of students per course
Course.includes(:enrollments).map { |c| [c.name, c.enrollments.count] }

# User type distribution
User.group(:user_type).count

# Enrollments via payment vs license
Enrollment.where(payable_type: 'Payment').count
Enrollment.where(payable_type: 'LicenseAccess').count

# School-specific metrics
school.students.count
school.instructors.count
school.management_users.count
```

## Next Steps
1. Generate controllers and views
2. Implement admin dashboard
3. Create student portal
4. Build instructor interface
5. Add enrollment flow
6. Implement license seat validation
7. Add payment processing integration 