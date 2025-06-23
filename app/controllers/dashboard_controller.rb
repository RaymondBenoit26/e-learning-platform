class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school

  def index
    # send the dashboard to the user based on their user type
    # student_dashboard, instructor_dashboard, management_dashboard, super_admin_dashboard
    send "#{current_user.user_type}_dashboard"
  end

  private

  def set_school
    @school = current_school
  end

  def student_dashboard
    @enrolled_courses = current_user.courses.includes(:instructors, :chapters)
    @available_courses = Course.where(school_id: @school.id)
                              .where.not(id: @enrolled_courses.ids)
                              .includes(:instructors)
                              .limit(6)
    @recent_enrollments = current_user.course_enrollments
                                  .order("enrollments.created_at DESC")
                                  .limit(5)
    @term_enrollments = current_user.term_enrollments.includes(:payable).limit(3)
    @available_licenses = License.where(licensable_type: "Term")
                                 .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                                 .where(terms: { school_id: @school.id })
                                 .available.limit(3)
    @my_licenses = current_user.licenses.limit(5)
  end

  def instructor_dashboard
    @assigned_courses = current_user.assigned_courses.includes(:students, :chapters)
    @total_students = @assigned_courses.joins(:students).distinct.count
    @recent_enrollments = Enrollment.course_enrollments.joins(:enrollable)
                                  .where(enrollable_id: @assigned_courses.pluck(:id))
                                  .includes(:student)
                                  .order("enrollments.created_at DESC")
                                  .limit(5)
    term_ids = @assigned_courses.joins(:term).pluck("terms.id").uniq
    @term_enrollments = Enrollment.term_enrollments.where(enrollable_id: term_ids)
                                      .includes(:student, :payable)
                                      .order(created_at: :desc)
                                      .limit(5)
  end

  def management_dashboard
    @total_students = @school.users.students.count
    @total_instructors = @school.users.instructors.count
    @total_courses = @school.courses.count
    @total_licenses = License.where(licensable_type: "Term")
                            .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                            .where(terms: { school_id: @school.id }).count
    @total_term_enrollments = Enrollment.term_enrollments.joins("INNER JOIN terms ON terms.id = enrollments.enrollable_id")
                                        .where(terms: { school_id: @school.id }).count
    @recent_enrollments = Enrollment.course_enrollments.joins("INNER JOIN courses ON courses.id = enrollments.enrollable_id")
                                      .where(courses: { school_id: @school.id })
                                      .includes(:student)
                                      .order("enrollments.created_at DESC")
                                      .limit(5)
    @recent_term_enrollments = Enrollment.term_enrollments.joins("INNER JOIN terms ON terms.id = enrollments.enrollable_id")
                                                .where(terms: { school_id: @school.id })
                                                .includes(:student, :payable)
                                                .order(created_at: :desc)
                                                .limit(5)
    @active_licenses = License.where(licensable_type: "Term")
                             .joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
                             .where(terms: { school_id: @school.id }).active
  end

  def super_admin_dashboard
    @total_schools = School.count
    @total_students = User.students.count
    @total_instructors = User.instructors.count
    @total_courses = Course.count
    @total_licenses = License.count
    @total_term_enrollments = Enrollment.term_enrollments.count
    @recent_schools = School.order(created_at: :desc).limit(5)
    @recent_enrollments = Enrollment.course_enrollments.includes(:student)
                                  .order(created_at: :desc)
                                  .limit(5)
    @recent_term_enrollments = Enrollment.term_enrollments.includes(:student, :payable)
                                                .order(created_at: :desc)
                                                .limit(5)
    @active_licenses = License.active.limit(5)
  end
end
