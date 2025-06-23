# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Clearing existing data..."
Enrollment.destroy_all
Payment.destroy_all
CourseAssignment.destroy_all
CourseContent.destroy_all
Chapter.destroy_all
Course.destroy_all
User.destroy_all
Term.destroy_all
School.destroy_all

# Create Schools
puts "Creating schools..."
school = School.create!(
  name: "Demo University",
  domain: "demo.edu",
  address: "123 Education St, Learning City, LC 12345",
  phone: "(555) 123-4567",
  email: "info@demo.edu"
)

# Create Terms
puts "Creating terms..."
fall_term = school.terms.create!(
  name: "Fall 2024",
  description: "Fall semester covering core curriculum courses and new student orientation programs.",
  start_date: Date.current.beginning_of_year + 8.months,
  end_date: Date.current.beginning_of_year + 12.months
)

spring_term = school.terms.create!(
  name: "Spring 2025",
  description: "Spring semester featuring advanced courses and preparation for summer programs.",
  start_date: Date.current.beginning_of_year + 12.months,
  end_date: Date.current.beginning_of_year + 16.months
)

# Add more terms for better testing
summer_term = school.terms.create!(
  name: "Summer 2025",
  description: "Intensive summer session with accelerated courses and special programs.",
  start_date: Date.current.beginning_of_year + 16.months,
  end_date: Date.current.beginning_of_year + 20.months
)

winter_term = school.terms.create!(
  name: "Winter 2025",
  description: "Winter session with specialized courses and research opportunities.",
  start_date: Date.current.beginning_of_year + 20.months,
  end_date: Date.current.beginning_of_year + 24.months
)

# Add a current term for immediate testing
current_term = school.terms.create!(
  name: "Current Term 2025",
  description: "Current academic term with ongoing courses and active enrollments.",
  start_date: Date.current - 1.month,
  end_date: Date.current + 2.months
)

# Add an upcoming term for enrollment testing
upcoming_term = school.terms.create!(
  name: "Upcoming Term 2025",
  description: "Upcoming term available for enrollment with new course offerings.",
  start_date: Date.current + 3.months,
  end_date: Date.current + 7.months
)

# Create Licenses
puts "Creating licenses..."

# Fall 2024 Licenses
fall_standard = fall_term.licenses.create!(
  name: "Fall 2024 Standard License",
  description: "Standard access to all courses in Fall 2024 term with basic features.",
  price: 299.99,
  max_seats: 100,
  license_type: "standard",
  expires_at: fall_term.end_date + 1.month
)

fall_premium = fall_term.licenses.create!(
  name: "Fall 2024 Premium License",
  description: "Premium access with additional features including 1-on-1 tutoring and priority support.",
  price: 499.99,
  max_seats: 50,
  license_type: "premium",
  expires_at: fall_term.end_date + 3.months
)

fall_free = fall_term.licenses.create!(
  name: "Fall 2024 Scholarship License",
  description: "Free access for scholarship students.",
  price: 0.00,
  max_seats: 20,
  license_type: "standard",
  expires_at: fall_term.end_date
)

# Spring 2025 Licenses
spring_standard = spring_term.licenses.create!(
  name: "Spring 2025 Standard License",
  description: "Standard access to all courses in Spring 2025 term.",
  price: 329.99,
  max_seats: 120,
  license_type: "standard",
  expires_at: spring_term.end_date + 1.month
)

spring_enterprise = spring_term.licenses.create!(
  name: "Spring 2025 Enterprise License",
  description: "Enterprise access with unlimited course access and advanced analytics.",
  price: 799.99,
  max_seats: 30,
  license_type: "enterprise",
  expires_at: spring_term.end_date + 6.months
)

spring_lifetime = spring_term.licenses.create!(
  name: "Lifetime Learning License",
  description: "Lifetime access to all current and future courses.",
  price: 1999.99,
  max_seats: 10,
  license_type: "lifetime",
  expires_at: nil  # Lifetime license
)

# Summer 2025 Licenses
summer_standard = summer_term.licenses.create!(
  name: "Summer 2025 Standard License",
  description: "Standard access to all summer courses and programs.",
  price: 249.99,
  max_seats: 80,
  license_type: "standard",
  expires_at: summer_term.end_date + 1.month
)

summer_intensive = summer_term.licenses.create!(
  name: "Summer 2025 Intensive License",
  description: "Intensive program access with extended support and resources.",
  price: 399.99,
  max_seats: 40,
  license_type: "premium",
  expires_at: summer_term.end_date + 2.months
)

# Winter 2025 Licenses
winter_standard = winter_term.licenses.create!(
  name: "Winter 2025 Standard License",
  description: "Standard access to winter session courses.",
  price: 279.99,
  max_seats: 60,
  license_type: "standard",
  expires_at: winter_term.end_date + 1.month
)

winter_research = winter_term.licenses.create!(
  name: "Winter 2025 Research License",
  description: "Research-focused license with access to advanced materials and mentorship.",
  price: 599.99,
  max_seats: 25,
  license_type: "enterprise",
  expires_at: winter_term.end_date + 3.months
)

# Current Term 2025 Licenses
current_standard = current_term.licenses.create!(
  name: "Current Term Standard License",
  description: "Standard access to current term courses.",
  price: 299.99,
  max_seats: 100,
  license_type: "standard",
  expires_at: current_term.end_date + 1.month
)

current_premium = current_term.licenses.create!(
  name: "Current Term Premium License",
  description: "Premium access with additional features and support.",
  price: 449.99,
  max_seats: 50,
  license_type: "premium",
  expires_at: current_term.end_date + 2.months
)

# Upcoming Term 2025 Licenses
upcoming_standard = upcoming_term.licenses.create!(
  name: "Upcoming Term Standard License",
  description: "Standard access to upcoming term courses.",
  price: 319.99,
  max_seats: 120,
  license_type: "standard",
  expires_at: upcoming_term.end_date + 1.month
)

upcoming_early_bird = upcoming_term.licenses.create!(
  name: "Upcoming Term Early Bird License",
  description: "Early bird discount for upcoming term enrollment.",
  price: 259.99,
  max_seats: 75,
  license_type: "standard",
  expires_at: upcoming_term.end_date + 1.month
)

upcoming_premium = upcoming_term.licenses.create!(
  name: "Upcoming Term Premium License",
  description: "Premium access to upcoming term with priority enrollment.",
  price: 479.99,
  max_seats: 60,
  license_type: "premium",
  expires_at: upcoming_term.end_date + 2.months
)

# Create Users
puts "Creating users..."

# Super Admin user
super_admin = User.create!(
  first_name: "Super",
  last_name: "Admin",
  email: "superadmin@elearning.com",
  password: "password123",
  password_confirmation: "password123",
  user_type: "super_admin", # Super admin user type
  phone: "(555) 000-0000",
  bio: "System super administrator with full access to all schools and management features."
)

# Management user
admin = school.users.create!(
  first_name: "Admin",
  last_name: "User",
  email: "admin@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "management",
  phone: "(555) 100-0001"
)

# Instructors
instructor1 = school.users.create!(
  first_name: "John",
  last_name: "Smith",
  email: "john.smith@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "instructor",
  phone: "(555) 100-0002",
  bio: "Professor of Computer Science with 10 years of teaching experience."
)

instructor2 = school.users.create!(
  first_name: "Sarah",
  last_name: "Johnson",
  email: "sarah.johnson@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "instructor",
  phone: "(555) 100-0003",
  bio: "Mathematics educator passionate about making learning engaging."
)

instructor3 = school.users.create!(
  first_name: "Michael",
  last_name: "Chen",
  email: "michael.chen@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "instructor",
  phone: "(555) 100-0004",
  bio: "Data Science expert with industry experience in machine learning and AI."
)

instructor4 = school.users.create!(
  first_name: "Emily",
  last_name: "Rodriguez",
  email: "emily.rodriguez@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "instructor",
  phone: "(555) 100-0005",
  bio: "Business and entrepreneurship instructor with startup experience."
)

instructor5 = school.users.create!(
  first_name: "David",
  last_name: "Thompson",
  email: "david.thompson@demo.edu",
  password: "password123",
  password_confirmation: "password123",
  user_type: "instructor",
  phone: "(555) 100-0006",
  bio: "Creative arts and design instructor specializing in digital media."
)

# Students
students = []
10.times do |i|
  students << school.users.create!(
    first_name: [ "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry", "Ivy", "Jack" ][i],
    last_name: [ "Anderson", "Brown", "Davis", "Evans", "Fisher", "Garcia", "Harris", "Jackson", "King", "Lee" ][i],
    email: "student#{i+1}@demo.edu",
    password: "password123",
    password_confirmation: "password123",
    user_type: "student",
    phone: "(555) 200-000#{i+1}"
  )
end

# Create Courses
puts "Creating courses..."

cs_course = school.courses.create!(
  name: "Introduction to Programming",
  description: "Learn the fundamentals of programming using Python. This course covers variables, loops, functions, and basic data structures.",
  term: fall_term,
  price: 89.99
)

math_course = school.courses.create!(
  name: "Calculus I",
  description: "Introduction to differential and integral calculus. Topics include limits, derivatives, and basic integration techniques.",
  term: fall_term,
  price: 79.99
)

web_course = school.courses.create!(
  name: "Web Development",
  description: "Learn to build modern web applications using HTML, CSS, JavaScript, and popular frameworks.",
  term: spring_term,
  price: 99.99
)

# Add more courses for different terms
data_science_course = school.courses.create!(
  name: "Data Science Fundamentals",
  description: "Introduction to data analysis, statistics, and machine learning using Python and R.",
  term: summer_term,
  price: 129.99
)

business_course = school.courses.create!(
  name: "Business Strategy & Entrepreneurship",
  description: "Learn business fundamentals, strategy development, and entrepreneurial skills.",
  term: summer_term,
  price: 149.99
)

ai_course = school.courses.create!(
  name: "Artificial Intelligence & Machine Learning",
  description: "Advanced course covering AI algorithms, neural networks, and practical ML applications.",
  term: winter_term,
  price: 179.99
)

design_course = school.courses.create!(
  name: "Digital Design & Creative Arts",
  description: "Explore digital design principles, graphic design, and creative expression through technology.",
  term: winter_term,
  price: 69.99
)

mobile_course = school.courses.create!(
  name: "Mobile App Development",
  description: "Build iOS and Android applications using modern development frameworks and tools.",
  term: current_term,
  price: 119.99
)

cybersecurity_course = school.courses.create!(
  name: "Cybersecurity Fundamentals",
  description: "Learn about network security, ethical hacking, and protecting digital assets.",
  term: current_term,
  price: 139.99
)

blockchain_course = school.courses.create!(
  name: "Blockchain & Cryptocurrency",
  description: "Understanding blockchain technology, smart contracts, and cryptocurrency systems.",
  term: upcoming_term,
  price: 159.99
)

cloud_course = school.courses.create!(
  name: "Cloud Computing & DevOps",
  description: "Learn cloud platforms, containerization, and modern software deployment practices.",
  term: upcoming_term,
  price: 109.99
)

# Assign instructors to courses
puts "Assigning instructors..."
cs_course.course_assignments.create!(instructor: instructor1, role: "primary")
math_course.course_assignments.create!(instructor: instructor2, role: "primary")
web_course.course_assignments.create!(instructor: instructor1, role: "primary")

# Assign instructors to new courses
data_science_course.course_assignments.create!(instructor: instructor3, role: "primary")
business_course.course_assignments.create!(instructor: instructor4, role: "primary")
ai_course.course_assignments.create!(instructor: instructor3, role: "primary")
design_course.course_assignments.create!(instructor: instructor5, role: "primary")
mobile_course.course_assignments.create!(instructor: instructor1, role: "primary")
cybersecurity_course.course_assignments.create!(instructor: instructor3, role: "primary")
blockchain_course.course_assignments.create!(instructor: instructor1, role: "primary")
cloud_course.course_assignments.create!(instructor: instructor1, role: "primary")

# Add some co-instructors for variety
data_science_course.course_assignments.create!(instructor: instructor2, role: "assistant")
ai_course.course_assignments.create!(instructor: instructor4, role: "assistant")

# Create chapters for courses
puts "Creating chapters..."

# Programming course chapters
cs_chapters = [
  { title: "Getting Started", description: "Introduction to programming concepts and setting up your environment", order: 1 },
  { title: "Variables and Data Types", description: "Understanding different types of data and how to store them", order: 2 },
  { title: "Control Structures", description: "Loops, conditionals, and program flow control", order: 3 },
  { title: "Functions", description: "Creating reusable code with functions and modules", order: 4 },
  { title: "Data Structures", description: "Lists, dictionaries, and other data organization methods", order: 5 }
]

cs_chapters.each do |chapter_data|
  chapter = cs_course.chapters.create!(chapter_data)

  # Add some course content to each chapter
  2.times do |i|
    chapter.course_contents.create!(
      course: cs_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Detailed content for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Math course chapters
math_chapters = [
  { title: "Limits", description: "Understanding limits and continuity", order: 1 },
  { title: "Derivatives", description: "Introduction to derivatives and differentiation rules", order: 2 },
  { title: "Applications of Derivatives", description: "Using derivatives to solve real-world problems", order: 3 },
  { title: "Integration", description: "Introduction to integrals and integration techniques", order: 4 }
]

math_chapters.each do |chapter_data|
  chapter = math_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: math_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Mathematical concepts and examples for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Web development chapters
web_chapters = [
  { title: "HTML Fundamentals", description: "Structure and semantics of web pages", order: 1 },
  { title: "CSS Styling", description: "Making web pages beautiful and responsive", order: 2 },
  { title: "JavaScript Basics", description: "Adding interactivity to web pages", order: 3 },
  { title: "Modern Frameworks", description: "Introduction to React and other frameworks", order: 4 }
]

web_chapters.each do |chapter_data|
  chapter = web_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: web_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Hands-on exercises for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Data Science course chapters
data_science_chapters = [
  { title: "Introduction to Data Science", description: "Overview of data science field and tools", order: 1 },
  { title: "Data Analysis with Python", description: "Using pandas and numpy for data manipulation", order: 2 },
  { title: "Statistical Analysis", description: "Basic statistics and hypothesis testing", order: 3 },
  { title: "Machine Learning Basics", description: "Introduction to supervised and unsupervised learning", order: 4 },
  { title: "Data Visualization", description: "Creating compelling visualizations with matplotlib and seaborn", order: 5 }
]

data_science_chapters.each do |chapter_data|
  chapter = data_science_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: data_science_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Data science concepts and practical examples for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Business course chapters
business_chapters = [
  { title: "Business Fundamentals", description: "Core business concepts and principles", order: 1 },
  { title: "Market Analysis", description: "Understanding markets and competitive landscape", order: 2 },
  { title: "Business Strategy", description: "Developing effective business strategies", order: 3 },
  { title: "Entrepreneurship", description: "Starting and growing a business", order: 4 },
  { title: "Business Planning", description: "Creating comprehensive business plans", order: 5 }
]

business_chapters.each do |chapter_data|
  chapter = business_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: business_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Business concepts and case studies for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# AI course chapters
ai_chapters = [
  { title: "AI Fundamentals", description: "Introduction to artificial intelligence concepts", order: 1 },
  { title: "Neural Networks", description: "Understanding and building neural networks", order: 2 },
  { title: "Deep Learning", description: "Advanced deep learning techniques", order: 3 },
  { title: "Natural Language Processing", description: "Working with text and language data", order: 4 },
  { title: "Computer Vision", description: "Image recognition and computer vision applications", order: 5 }
]

ai_chapters.each do |chapter_data|
  chapter = ai_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: ai_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "AI and ML concepts for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Design course chapters
design_chapters = [
  { title: "Design Principles", description: "Fundamental principles of design", order: 1 },
  { title: "Digital Tools", description: "Using design software and digital tools", order: 2 },
  { title: "Typography", description: "Working with fonts and text design", order: 3 },
  { title: "Color Theory", description: "Understanding color and its impact", order: 4 },
  { title: "Creative Projects", description: "Hands-on design projects and portfolio building", order: 5 }
]

design_chapters.each do |chapter_data|
  chapter = design_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: design_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Design concepts and creative exercises for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Mobile development chapters
mobile_chapters = [
  { title: "Mobile Development Basics", description: "Introduction to mobile app development", order: 1 },
  { title: "iOS Development", description: "Building apps for iPhone and iPad", order: 2 },
  { title: "Android Development", description: "Creating Android applications", order: 3 },
  { title: "Cross-Platform Development", description: "Using React Native and Flutter", order: 4 },
  { title: "App Store Deployment", description: "Publishing apps to app stores", order: 5 }
]

mobile_chapters.each do |chapter_data|
  chapter = mobile_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: mobile_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Mobile development tutorials for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Cybersecurity chapters
cybersecurity_chapters = [
  { title: "Security Fundamentals", description: "Basic cybersecurity concepts and threats", order: 1 },
  { title: "Network Security", description: "Protecting network infrastructure", order: 2 },
  { title: "Web Security", description: "Securing web applications and services", order: 3 },
  { title: "Ethical Hacking", description: "Penetration testing and vulnerability assessment", order: 4 },
  { title: "Security Best Practices", description: "Implementing security in organizations", order: 5 }
]

cybersecurity_chapters.each do |chapter_data|
  chapter = cybersecurity_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: cybersecurity_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Cybersecurity concepts and practical exercises for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Blockchain chapters
blockchain_chapters = [
  { title: "Blockchain Basics", description: "Understanding blockchain technology", order: 1 },
  { title: "Cryptocurrency", description: "Bitcoin, Ethereum, and other cryptocurrencies", order: 2 },
  { title: "Smart Contracts", description: "Building and deploying smart contracts", order: 3 },
  { title: "DeFi Applications", description: "Decentralized finance and applications", order: 4 },
  { title: "Blockchain Development", description: "Building blockchain applications", order: 5 }
]

blockchain_chapters.each do |chapter_data|
  chapter = blockchain_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: blockchain_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Blockchain concepts and development for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Cloud computing chapters
cloud_chapters = [
  { title: "Cloud Fundamentals", description: "Introduction to cloud computing concepts", order: 1 },
  { title: "AWS Services", description: "Amazon Web Services and cloud infrastructure", order: 2 },
  { title: "Containerization", description: "Docker and container technologies", order: 3 },
  { title: "DevOps Practices", description: "Continuous integration and deployment", order: 4 },
  { title: "Cloud Security", description: "Securing cloud infrastructure and applications", order: 5 }
]

cloud_chapters.each do |chapter_data|
  chapter = cloud_course.chapters.create!(chapter_data)

  2.times do |i|
    chapter.course_contents.create!(
      course: cloud_course,
      title: "Lesson #{i+1}: #{chapter.title}",
      description: "Cloud computing and DevOps concepts for #{chapter.title.downcase}",
      content_type: [ "video", "document", "presentation" ].sample
    )
  end
end

# Create License Accesses
puts "Creating license accesses..."

# Give some students license access
students[0..2].each do |student|
  fall_premium.license_accesses.create!(student: student, status: 'active')
end

students[3..5].each do |student|
  fall_standard.license_accesses.create!(student: student, status: 'active')
end

students[6..7].each do |student|
  fall_free.license_accesses.create!(student: student, status: 'active')
end

students[8..9].each do |student|
  spring_standard.license_accesses.create!(student: student, status: 'active')
end

# Create license accesses for other terms (summer, winter, current)
students[0..2].each do |student|
  summer_intensive.license_accesses.create!(student: student, status: 'active')
end

students[3..5].each do |student|
  winter_research.license_accesses.create!(student: student, status: 'active')
end

students[6..8].each do |student|
  current_premium.license_accesses.create!(student: student, status: 'active')
end

# Note: Term enrollments are automatically created by LicenseAccess callbacks
puts "Term enrollments will be created automatically via LicenseAccess..."

# Create payments for license accesses (separate from automatic enrollment creation)
puts "Creating payments for license purchases..."

# Create payments for fall term license accesses
students[0..2].each do |student|
  if fall_premium.price > 0
    student.payments.create!(
      amount: fall_premium.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: fall_premium
    )
  end
end

students[3..5].each do |student|
  if fall_standard.price > 0
    student.payments.create!(
      amount: fall_standard.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: fall_standard
    )
  end
end

# Create payments for spring term license accesses
students[8..9].each do |student|
  if spring_standard.price > 0
    student.payments.create!(
      amount: spring_standard.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: spring_standard
    )
  end
end

# Create payments for summer term license accesses
students[0..2].each do |student|
  if summer_intensive.price > 0
    student.payments.create!(
      amount: summer_intensive.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: summer_intensive
    )
  end
end

# Create payments for winter term license accesses
students[3..5].each do |student|
  if winter_research.price > 0
    student.payments.create!(
      amount: winter_research.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: winter_research
    )
  end
end

# Create payments for current term license accesses
students[6..8].each do |student|
  if current_premium.price > 0
    student.payments.create!(
      amount: current_premium.price,
      payment_method: 'credit_card',
      status: 'completed',
      payable: current_premium
    )
  end
end

# Note: Upcoming term has no enrollments yet - perfect for testing new enrollments!

# Create course enrollments
puts "Creating course enrollments..."

# Enroll students in courses (course-based enrollments)
students.each_with_index do |student, index|
  # Each student enrolls in 1-3 courses from all available courses
  all_courses = [ cs_course, math_course, web_course, data_science_course, business_course,
                 ai_course, design_course, mobile_course, cybersecurity_course,
                 blockchain_course, cloud_course ]

  courses_to_enroll = all_courses.sample(rand(1..3))

  courses_to_enroll.each do |course|
    # Create course enrollment (not term-based) - use find_or_create_by to avoid duplicates
    course.enrollments.find_or_create_by(
      student: student,
      enrollable: course,
      enrollment_type: "course"
    ) do |enrollment|
      enrollment.status = "active"
    end
  end
end

# Create licenses for courses
puts "Creating course licenses..."

# Get the first course
course = Course.first
if course
  # Create a premium license for the course
  course.licenses.create!(
    name: "Premium Course Access",
    description: "Full access to all course content with premium features",
    price: 99.99,
    max_seats: 50,
    license_type: "premium",
    expires_at: 1.year.from_now
  )

  # Create a standard license for the course
  course.licenses.create!(
    name: "Standard Course Access",
    description: "Basic access to course content",
    price: 49.99,
    max_seats: 100,
    license_type: "standard",
    expires_at: 6.months.from_now
  )

  puts "Created licenses for course: #{course.name}"
end

# Create licenses for terms (existing code)
puts "Creating term licenses..."

puts "Seed completed successfully!"
puts ""
puts "=== Login Credentials ==="
puts "Super Admin: superadmin@elearning.com / password123"
puts "Admin: admin@demo.edu / password123"
puts "Instructor: john.smith@demo.edu / password123"
puts "Instructor: sarah.johnson@demo.edu / password123"
puts "Instructor: michael.chen@demo.edu / password123"
puts "Instructor: emily.rodriguez@demo.edu / password123"
puts "Instructor: david.thompson@demo.edu / password123"
puts "Student: student1@demo.edu / password123"
puts "... (students 1-10 all use password123)"
puts ""
puts "=== Summary ==="
puts "Schools: #{School.count}"
puts "Users: #{User.count} (#{User.students.count} students, #{User.instructors.count} instructors, #{User.management.count} management, #{User.super_admins.count} super admin)"
puts "Terms: #{Term.count} (Fall 2024, Spring 2025, Summer 2025, Winter 2025, Current Term 2025, Upcoming Term 2025)"
puts "Courses: #{Course.count} (11 courses across 6 terms)"
puts "Chapters: #{Chapter.count}"
puts "Course Contents: #{CourseContent.count}"
puts "Licenses: #{License.count} (multiple license types per term)"
puts "License Accesses: #{LicenseAccess.count}"
puts "Course Enrollments: #{Enrollment.course_enrollments.count}"
puts "Term Enrollments: #{Enrollment.term_enrollments.count}"
puts "Payments: #{Payment.count}"
puts ""
puts "=== Testing Notes ==="
puts "• Upcoming Term 2025 has no enrollments - perfect for testing new enrollments!"
puts "• Current Term 2025 is active - test current term features"
puts "• Multiple license types available for each term"
puts "• Students have various enrollment combinations across terms and courses"
