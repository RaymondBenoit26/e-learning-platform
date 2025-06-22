class ChaptersController < ApplicationController
  include CourseAccess

  before_action :set_course
  before_action :set_chapter, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_course_access!, only: [ :show, :index ]
  before_action :ensure_management_or_instructor!, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    @chapters = @course.chapters.order(:order)
  end

  def show
    @course_contents = @chapter.course_contents.order("course_contents.created_at")
  end

  def new
    @chapter = @course.chapters.build
    @chapter.order = (@course.chapters.maximum(:order) || 0) + 1
  end

  def create
    @chapter = @course.chapters.build(chapter_params)

    if @chapter.save
      redirect_to [ @course.school, @course, @chapter ], notice: "Chapter was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to [ @course.school, @course, @chapter ], notice: "Chapter was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chapter.destroy
    redirect_to [ @course.school, @course ], notice: "Chapter was successfully deleted."
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
    @school = @course.school
  end

  def set_chapter
    @chapter = @course.chapters.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(:title, :description, :order)
  end

  def ensure_management_or_instructor!
    unless current_user.management? ||
           (current_user.instructor? && current_user.assigned_courses.include?(@course))
      redirect_to root_path, alert: "Access denied. Only instructors and management can modify chapters."
    end
  end
end
