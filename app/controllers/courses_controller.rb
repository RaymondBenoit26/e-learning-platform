class CoursesController < ApplicationController
  include CourseAccess

  before_action :set_course, only: [ :show, :edit, :update, :enroll, :unenroll ]
  before_action :set_school, only: [ :index, :new, :create ]

  def index
    if params[:school_id]
      # School-scoped courses (for management/instructors)
      @q = @school.courses.includes(:instructors, :students, :term).ransack(params[:q])
      @courses = @q.result(distinct: true)
    else
      # Global course browsing (for students)
      @q = Course.where(school_id: current_school.id).includes(:instructors, :students, :term).ransack(params[:q])
      @courses = @q.result(distinct: true)
      @enrolled_course_ids = current_user.courses.pluck(:id) if current_user.student?
    end
  end

  def show
    @chapters = @course.chapters.order(:order)
    @instructors = @course.instructors

    if current_user.student?
      # Check if user has access to this course through:
      # 1. Direct course enrollment
      # 2. Term enrollment (if course belongs to a term)
      @enrolled = has_course_access?(@course)
      @access_method = determine_access_method(@course)
      @can_enroll = !@enrolled
    else
      @enrolled = false
      @can_enroll = false
    end
  end

  def new
    @course = @school.courses.build
  end

  def create
    @course = @school.courses.build(course_params)

    if @course.save
      # Assign current user as instructor if they're an instructor
      if current_user.instructor?
        @course.course_assignments.create!(instructor: current_user, role: "primary")
      end

      redirect_to [ @school, @course ], notice: "Course was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @course.update(course_params)
      redirect_to [ @course.school, @course ], notice: "Course was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def enroll
    if current_user.student?
      # Check if course is free
      if @course.free?
        enrollment = @course.enrollments.build(student: current_user, status: :active)

        if enrollment.save
          redirect_to @course, notice: "Successfully enrolled in course!"
        else
          redirect_to @course, alert: "Failed to enroll in course."
        end
      else
        # For paid courses, redirect to payment flow
        redirect_to new_school_course_payment_path(@school, @course),
                    alert: "This course requires payment. Please complete the payment process."
      end
    else
      redirect_to @course, alert: "Only students can enroll in courses."
    end
  end

  def unenroll
    if current_user.student?
      enrollment = @course.enrollments.find_by(student: current_user)
      if enrollment&.destroy
        redirect_to @course, notice: "Successfully unenrolled from course."
      else
        redirect_to @course, alert: "Failed to unenroll from course."
      end
    else
      redirect_to @course, alert: "Invalid action."
    end
  end

  private

  def set_course
    if params[:school_id]
      @course = School.find(params[:school_id]).courses.find(params[:id])
    else
      @course = Course.find(params[:id])
    end
    @school = @course.school
  end

  def set_school
    @school = School.find(params[:school_id]) if params[:school_id]
  end

  def course_params
    params.require(:course).permit(:name, :description, :term_id, :price)
  end
end
