# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    case user.user_type
    when "management"
      can :manage, :all
    when "instructor"
      can :read, Course, course_assignments: { instructor_id: user.id }
      can :manage, Course, course_assignments: { instructor_id: user.id }
      can :manage, Chapter, course: { course_assignments: { instructor_id: user.id } }
      can :manage, CourseContent, course: { course_assignments: { instructor_id: user.id } }
    when "student"
      can :read, Course, enrollments: { student_id: user.id }
      can :read, Chapter, course: { enrollments: { student_id: user.id } }
      can :read, CourseContent, course: { enrollments: { student_id: user.id } }
    end
  end
end
