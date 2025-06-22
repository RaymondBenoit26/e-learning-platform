class CourseContentsController < ApplicationController
  include CourseAccess

  before_action :set_school
  before_action :set_course
  before_action :set_chapter, only: [ :new, :create ]
  before_action :set_course_content, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_course_access!, only: [ :show ]
  before_action :ensure_authorized_user, except: [ :show ]

  def show
    # Show course content details
  end

  def new
    @course_content = @course.course_contents.build
    @course_content.chapter = @chapter if @chapter
  end

  def create
    @course_content = @course.course_contents.build(course_content_params)
    @course_content.chapter = @chapter if @chapter

    if @course_content.save
      redirect_to [ @school, @course, @chapter, @course_content ], notice: "Course content was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @course_content.update(course_content_params)
      redirect_to [ @school, @course, @course_content.chapter, @course_content ], notice: "Course content was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course_content.destroy
    redirect_to [ @school, @course, @course_content.chapter ], notice: "Course content was successfully deleted."
  end

  private

  def set_school
    @school = School.find(params[:school_id])
    redirect_to root_path unless @school == current_school
  end

  def set_course
    @course = @school.courses.find(params[:course_id])
  end

  def set_chapter
    @chapter = @course.chapters.find(params[:chapter_id]) if params[:chapter_id]
  end

  def set_course_content
    if params[:chapter_id]
      @chapter = @course.chapters.find(params[:chapter_id])
      @course_content = @chapter.course_contents.find(params[:id])
    else
      @course_content = @course.course_contents.find(params[:id])
    end
  end

  def ensure_authorized_user
    # For editing/creating content, only management and instructors should have access
    unless current_user.management? ||
           (current_user.instructor? && current_user.assigned_courses.include?(@course))
      redirect_to root_path, alert: "Access denied. Only instructors and management can modify course content."
    end
  end

  def course_content_params
    params.require(:course_content).permit(:title, :description, :content_type, :file, :chapter_id)
  end
end
