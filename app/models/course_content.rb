class CourseContent < ApplicationRecord
  belongs_to :course
  belongs_to :chapter, optional: true

  has_one_attached :file
end
