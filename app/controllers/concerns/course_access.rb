module CourseAccess
  extend ActiveSupport::Concern

  private

  # Check if current user has access to the course
  def has_course_access?(course)
    return true if current_user.management?
    return true if current_user.instructor? && current_user.assigned_courses.include?(course)
    return false unless current_user.student?

    # Method 1: Active direct course enrollment (highest priority)
    direct_enrollment = current_user.course_enrollments.find_by(enrollable: course)
    return true if direct_enrollment&.active?

    # Method 2: Active term enrollment (if course belongs to a term)
    if course.term.present?
      term_enrollment = current_user.term_enrollments.find_by(enrollable: course.term)
      return true if term_enrollment&.active?
    end

    false
  end

  # Determine how the user has access to the course
  def determine_access_method(course)
    return :management if current_user.management?
    return :instructor if current_user.instructor? && current_user.assigned_courses.include?(course)
    return nil unless current_user.student?

    # Check direct enrollment first (priority)
    direct_enrollment = current_user.course_enrollments.find_by(enrollable: course)
    return :direct_enrollment if direct_enrollment&.active?

    # Check term enrollment second
    if course.term.present?
      term_enrollment = current_user.term_enrollments.find_by(enrollable: course.term)
      return :term_enrollment if term_enrollment&.active?
    end

    nil
  end

  # Ensure user has access to the course, redirect if not
  def ensure_course_access!
    unless has_course_access?(@course)
      message = generate_access_denied_message(@course)
      redirect_to root_path, alert: message
    end
  end

  # Generate appropriate access denied message based on enrollment status
  def generate_access_denied_message(course)
    return "Access denied. You must be enrolled in this course or its term to access this content." unless current_user.student?

    messages = []

    # Check direct course enrollment status
    direct_enrollment = current_user.course_enrollments.find_by(enrollable: course)
    if direct_enrollment
      case direct_enrollment.status
      when "pending"
        messages << "Your course enrollment is pending payment processing"
      when "inactive"
        messages << "Your course enrollment is inactive"
      else
        messages << "Your course enrollment status: #{direct_enrollment.status}"
      end
    end

    # Check term enrollment status if course belongs to a term
    if course.term.present?
      term_enrollment = current_user.term_enrollments.find_by(enrollable: course.term)
      if term_enrollment
        case term_enrollment.status
        when "pending"
          messages << "Your term enrollment (#{course.term.name}) is pending payment processing"
        when "inactive"
          messages << "Your term enrollment (#{course.term.name}) is inactive"
        else
          messages << "Your term enrollment status: #{term_enrollment.status}"
        end
      end
    end

    if messages.any?
      "Access denied. #{messages.join('. ')}. Only active enrollments grant access to course content."
    else
      "Access denied. You must enroll in this course or its term to access this content."
    end
  end
end
