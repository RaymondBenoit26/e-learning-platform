class Chapter < ApplicationRecord
  belongs_to :course
  has_many :course_contents, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :order, presence: true, uniqueness: { scope: :course_id }
  validates :order, numericality: { greater_than: 0 }
end
