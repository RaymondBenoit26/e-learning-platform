class TermsController < ApplicationController
  before_action :set_school
  before_action :set_term, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_management_user, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    @q = @school.terms.ransack(params[:q])
    @terms = @q.result(distinct: true).order(start_date: :desc)

    # For students, show only upcoming terms
    @terms = @terms.upcoming if current_user.student?
  end

  def show
    @courses = @term.courses.includes(:instructors, :students)
    @enrolled = current_user.student? && current_user.term_enrollments.exists?(enrollable: @term)
    @can_enroll = current_user.student? && !@enrolled && @term.status == "upcoming"
    @available_licenses = @term.licenses.available if current_user.student?
  end

  def new
    @term = @school.terms.build
  end

  def create
    @term = @school.terms.build(term_params)

    if @term.save
      redirect_to [ @school, @term ], notice: "Term was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @term.update(term_params)
      redirect_to [ @school, @term ], notice: "Term was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @term.courses.any?
      redirect_to [ @school, @term ], alert: "Cannot delete term with existing courses."
    else
      @term.destroy
      redirect_to school_terms_path(@school), notice: "Term was successfully deleted."
    end
  end

  def licenses
    @term = @school.terms.find(params[:id])
    licenses = @term.licenses.includes(:students).map do |license|
      {
        id: license.id,
        name: license.name,
        price: license.price,
        available_seats: license.available_seats,
        license_type: license.license_type,
        expires_at: license.expires_at
      }
    end

    render json: licenses
  end

  private

  def set_school
    @school = School.find(params[:school_id])
    redirect_to root_path unless @school == current_school
  end

  def set_term
    @term = @school.terms.find(params[:id])
  end

  def ensure_management_user
    redirect_to root_path, alert: "Access denied." unless current_user.management?
  end

  def term_params
    params.require(:term).permit(:name, :start_date, :end_date, :description)
  end
end
